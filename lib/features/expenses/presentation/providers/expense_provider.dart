import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/utils/view_state.dart';
import '../../../wallet/domain/entities/user_card.dart';
import '../../domain/entities/bill_notice.dart';
import '../../domain/entities/card_milestone.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/recurring_charge.dart';
import '../../domain/entities/sms_parse_result.dart';
import '../../domain/entities/sms_tracking_status.dart';
import '../../domain/entities/spend_analytics.dart';
import '../../domain/entities/spend_category.dart';
import '../../domain/entities/tracked_card_ref.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/services/bill_status_resolver.dart';
import '../../domain/services/milestone_calculator.dart';
import '../../domain/services/recurring_charge_detector.dart';
import '../../domain/services/spend_analytics_calculator.dart';

/// State machine for SMS spend tracking and analytics.
///
/// Local-first: the UI always renders cached, on-device data; scanning and
/// backend sync run in the background and only update status indicators.
/// Strictly ZERO setState — widgets observe via Selector/Consumer.
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  final SpendAnalyticsCalculator _analyticsCalculator;
  final RecurringChargeDetector _recurringDetector;
  final MilestoneCalculator _milestoneCalculator;
  final BillStatusResolver _billResolver;
  final bool _observeLifecycle;
  final DateTime Function() _clock;

  ExpenseProvider(
    this._repository, {
    SpendAnalyticsCalculator analyticsCalculator = const SpendAnalyticsCalculator(),
    RecurringChargeDetector recurringDetector = const RecurringChargeDetector(),
    MilestoneCalculator milestoneCalculator = const MilestoneCalculator(),
    BillStatusResolver billResolver = const BillStatusResolver(),
    bool observeLifecycle = true,
    DateTime Function()? clock,
  })  : _analyticsCalculator = analyticsCalculator,
        _recurringDetector = recurringDetector,
        _milestoneCalculator = milestoneCalculator,
        _billResolver = billResolver,
        _observeLifecycle = observeLifecycle,
        _clock = clock ?? DateTime.now {
    final (start, end) = SpendAnalyticsCalculator.rangeFor(_period, _clock());
    _analytics = SpendAnalytics.empty(_period, start, end);
  }

  /// Delay after a new-bank-SMS ping before re-reading the inbox, giving the
  /// default SMS app time to persist the message.
  static const Duration incomingScanDelay = Duration(seconds: 3);

  ViewState _state = ViewState.initial;
  String? _errorMessage;
  SmsConsent _consent = SmsConsent.initial;
  SmsPermissionStatus _permission = SmsPermissionStatus.denied;
  ExpenseSyncStatus _syncStatus = ExpenseSyncStatus.idle;
  DateTime? _lastSyncedAt;
  bool _isScanning = false;
  SmsScanReport? _lastScan;
  bool _disposed = false;

  List<CardTransaction> _transactions = const [];
  List<BillNotice> _bills = const [];
  List<TrackedCardRef> _cards = const [];
  List<CardMilestone> _milestones = const [];
  AnalyticsPeriod _period = AnalyticsPeriod.thisMonth;
  TransactionFilter _filter = TransactionFilter.none;

  late SpendAnalytics _analytics;
  List<RecurringCharge> _recurring = const [];
  List<BillStatus> _billStatuses = const [];
  List<MilestoneProgress> _milestoneProgress = const [];
  List<CardTransaction> _filtered = const [];

  AppLifecycleListener? _lifecycleListener;
  StreamSubscription<DateTime>? _incomingSub;
  Timer? _incomingDebounce;

  // ---- Getters ----
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  SmsConsent get consent => _consent;
  SmsPermissionStatus get permission => _permission;
  ExpenseSyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isScanning => _isScanning;
  SmsScanReport? get lastScan => _lastScan;
  int get pendingSyncCount => _repository.pendingSyncCount;
  List<CardTransaction> get transactions => _transactions;
  List<CardTransaction> get filteredTransactions => _filtered;
  List<TrackedCardRef> get cards => _cards;
  AnalyticsPeriod get period => _period;
  TransactionFilter get filter => _filter;
  SpendAnalytics get analytics => _analytics;
  List<RecurringCharge> get recurringCharges => _recurring;
  List<BillStatus> get billStatuses => _billStatuses;
  List<MilestoneProgress> get milestoneProgress => _milestoneProgress;

  bool get isSmsSupported => _repository.isSmsSupported;

  /// Consent granted, permission granted and on a platform that can read SMS.
  bool get isTrackingActive =>
      isSmsSupported && _consent.isGranted && _permission == SmsPermissionStatus.granted;

  /// Show the onboarding / prominent disclosure prompt.
  bool get needsConsentDecision =>
      isSmsSupported && (_consent.status == SmsConsentStatus.notAsked || _consent.version != SmsConsent.currentVersion);

  /// Distinct card last-4s seen in alerts (for list filters).
  List<String> get knownCardLast4s =>
      {for (final t in _transactions) if (t.cardLast4 != null) t.cardLast4!}.toList()..sort();

  /// Initial load: cached data first, then background scan + sync.
  Future<void> init() async {
    if (!_state.isInitial) return;
    _setState(ViewState.loading);
    try {
      _consent = _repository.getConsent();
      _permission = await _repository.getSmsPermissionStatus();
      _lastSyncedAt = _repository.lastSyncedAt;
      await _reloadFromCache();
      _setState(_hasData ? ViewState.loaded : ViewState.empty);
    } catch (e) {
      _errorMessage = 'Could not load your spend history. Please try again.';
      _setState(ViewState.error);
      return;
    }

    if (_observeLifecycle) {
      _lifecycleListener = AppLifecycleListener(onResume: _onResume);
    }
    unawaited(_loadMilestones());
    if (isTrackingActive) {
      _listenForIncoming();
      unawaited(_scanAndSync());
    } else {
      unawaited(_sync());
    }
  }

  bool get _hasData => _transactions.isNotEmpty || _bills.isNotEmpty;

  /// Pull-to-refresh / retry: rescans the inbox (when active) and syncs.
  Future<void> refresh() async {
    if (_state.isError || _state.isInitial) {
      _state = ViewState.initial;
      await init();
      return;
    }
    _setState(_hasData ? ViewState.refreshing : ViewState.loading);
    _permission = await _repository.getSmsPermissionStatus();
    await _scanAndSync();
    _setState(_hasData ? ViewState.loaded : ViewState.empty);
  }

  /// Records consent after the prominent disclosure and requests the runtime
  /// permission. Returns true when tracking is active afterwards.
  Future<bool> grantConsentAndEnable() async {
    _consent = SmsConsent(status: SmsConsentStatus.granted, decidedAt: _clock());
    await _repository.saveConsent(_consent);
    _permission = await _repository.requestSmsPermission();
    _notify();
    if (!isTrackingActive) return false;

    _listenForIncoming();
    _setState(_hasData ? ViewState.refreshing : ViewState.loading);
    await _scanAndSync(fullRescan: true);
    _setState(_hasData ? ViewState.loaded : ViewState.empty);
    return true;
  }

  /// User chose "Not now" on the disclosure; manual/paste entry stays available.
  Future<void> declineConsent() async {
    _consent = SmsConsent(status: SmsConsentStatus.declined, decidedAt: _clock());
    await _repository.saveConsent(_consent);
    _notify();
  }

  /// Withdraws consent: stops reading SMS. Existing data is kept until deleted.
  Future<void> pauseTracking() async {
    _consent = SmsConsent(status: SmsConsentStatus.withdrawn, decidedAt: _clock());
    await _repository.saveConsent(_consent);
    _stopListening();
    _notify();
  }

  /// Opens system settings (needed when the permission is permanently denied).
  Future<void> openAppSettings() => _repository.openAppSettings();

  /// Re-reads the whole 180-day backfill window (dedupe prevents duplicates).
  Future<void> fullRescan() async {
    if (!isTrackingActive) return;
    _setState(_hasData ? ViewState.refreshing : ViewState.loading);
    await _scanAndSync(fullRescan: true);
    _setState(_hasData ? ViewState.loaded : ViewState.empty);
  }

  /// Uploads queued records now.
  Future<void> syncNow() => _sync();

  /// Keeps card matching in step with the wallet (called by ProxyProvider).
  void updateCards(List<UserCard> walletCards) {
    final refs = [
      for (final c in walletCards)
        TrackedCardRef(
          userCardId: c.id,
          last4: c.last4Digits,
          label: c.nickname,
          bankName: c.bankName,
          cardName: c.cardName,
          annualFee: c.annualFee,
        ),
    ];
    if (_sameCards(refs)) return;
    _cards = refs;
    // Deferred: ProxyProvider.update runs during build.
    scheduleMicrotask(() async {
      await _repository.relinkCards(refs);
      await _reloadFromCache();
      await _loadMilestones();
    });
  }

  bool _sameCards(List<TrackedCardRef> refs) {
    if (refs.length != _cards.length) return false;
    for (var i = 0; i < refs.length; i++) {
      final a = refs[i];
      final b = _cards[i];
      if (a.userCardId != b.userCardId || a.last4 != b.last4 || a.label != b.label) return false;
    }
    return true;
  }

  /// Switches the analytics window.
  void setPeriod(AnalyticsPeriod period) {
    if (_period == period) return;
    _period = period;
    _recompute();
    _notify();
  }

  /// Applies a transaction list filter.
  void setFilter(TransactionFilter filter) {
    _filter = filter;
    _filtered = _transactions.where(_filter.matches).toList();
    _notify();
  }

  /// Parse-only preview for the paste screen (no persistence).
  SmsParseOutcome previewPastedSms(String text) => _repository.previewPastedSms(text);

  /// Saves a pasted SMS if it parses. Returns the outcome or an error message.
  Future<(SmsParseOutcome?, String?)> importPastedSms(String text) async {
    final result = await _repository.importPastedSms(text);
    await _reloadFromCache();
    _setState(_hasData ? ViewState.loaded : ViewState.empty);
    unawaited(_sync());
    return result.when(success: (o) => (o, null), failure: (msg, _) => (null, msg));
  }

  /// Adds a manual transaction. Returns an error message on failure.
  Future<String?> addManualTransaction({
    required double amount,
    required String merchant,
    required SpendCategory category,
    required TransactionType type,
    required DateTime occurredAt,
    int? userCardId,
  }) async {
    TrackedCardRef? card;
    for (final c in _cards) {
      if (c.userCardId == userCardId) card = c;
    }
    final result = await _repository.addManualTransaction(
      amount: amount,
      merchant: merchant,
      category: category,
      type: type,
      occurredAt: occurredAt,
      card: card,
    );
    if (result.isFailure) return result.errorOrNull;
    await _reloadFromCache();
    _setState(ViewState.loaded);
    unawaited(_sync());
    return null;
  }

  /// User override of a category (learned by the backend as feedback).
  Future<void> recategorize(String transactionId, SpendCategory category) async {
    await _repository.updateCategory(transactionId, category);
    await _reloadFromCache();
    unawaited(_sync());
  }

  /// Hides a mis-parsed record permanently.
  Future<void> excludeTransaction(String transactionId) async {
    await _repository.excludeTransaction(transactionId);
    await _reloadFromCache();
    _setState(_hasData ? ViewState.loaded : ViewState.empty);
    unawaited(_sync());
  }

  /// Erases all SMS-derived data on device and backend and withdraws consent.
  Future<bool> deleteAllData() async {
    _stopListening();
    final result = await _repository.deleteAllData();
    _consent = _repository.getConsent();
    _lastScan = null;
    _lastSyncedAt = null;
    await _reloadFromCache();
    _setState(ViewState.empty);
    return result.isSuccess;
  }

  /// Clears local data on sign-out so the next account starts clean.
  Future<void> clearOnSignOut() async {
    _stopListening();
    await _repository.clearLocalData();
    _consent = _repository.getConsent();
    _lastScan = null;
    _lastSyncedAt = null;
    _syncStatus = ExpenseSyncStatus.idle;
    await _reloadFromCache();
    _setState(ViewState.empty);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _onResume() async {
    final previous = _permission;
    _permission = await _repository.getSmsPermissionStatus();
    if (isTrackingActive) {
      _listenForIncoming();
      await _scanAndSync();
    } else {
      _stopListening();
      if (previous != _permission) _notify();
    }
  }

  void _listenForIncoming() {
    if (_incomingSub != null) return;
    _incomingSub = _repository.watchIncomingBankSms().listen(
      (_) {
        _incomingDebounce?.cancel();
        _incomingDebounce = Timer(incomingScanDelay, () => unawaited(_scanAndSync()));
      },
      onError: (Object _) => _stopListening(),
    );
  }

  void _stopListening() {
    _incomingDebounce?.cancel();
    _incomingDebounce = null;
    _incomingSub?.cancel();
    _incomingSub = null;
  }

  Future<void> _scanAndSync({bool fullRescan = false}) async {
    if (isTrackingActive && !_isScanning) {
      _isScanning = true;
      _notify();
      final result = await _repository.scanInbox(fullRescan: fullRescan);
      result.when(
        success: (report) {
          _lastScan = report;
          _errorMessage = null;
        },
        failure: (message, _) => _errorMessage = message,
      );
      _isScanning = false;
      await _reloadFromCache();
      if (_state.isLoaded || _state.isEmpty) _state = _hasData ? ViewState.loaded : ViewState.empty;
      _notify();
    }
    await _sync();
  }

  Future<void> _sync() async {
    if (_syncStatus == ExpenseSyncStatus.syncing) return;
    _syncStatus = ExpenseSyncStatus.syncing;
    _notify();
    final result = await _repository.syncPending();
    result.when(
      success: (report) => _syncStatus = report.status,
      failure: (_, _) => _syncStatus = ExpenseSyncStatus.serverError,
    );
    _lastSyncedAt = _repository.lastSyncedAt;
    if (_syncStatus == ExpenseSyncStatus.synced) await _reloadFromCache();
    _notify();
  }

  Future<void> _loadMilestones() async {
    if (_cards.isEmpty) {
      _milestones = const [];
    } else {
      final result = await _repository.getMilestones(_cards);
      _milestones = result.dataOrNull ?? const [];
    }
    _recompute();
    _notify();
  }

  Future<void> _reloadFromCache() async {
    _transactions = await _repository.getCachedTransactions();
    _bills = await _repository.getCachedBills();
    _recompute();
    _notify();
  }

  void _recompute() {
    final now = _clock();
    _analytics = _analyticsCalculator.compute(
      transactions: _transactions,
      period: _period,
      cards: _cards,
      now: now,
    );
    _recurring = _recurringDetector.detect(_transactions, now: now);
    _billStatuses = _billResolver.resolve(_bills, _transactions, now: now);
    _filtered = _transactions.where(_filter.matches).toList();

    final labels = {for (final c in _cards) c.userCardId: c.label};
    _milestoneProgress = [
      for (final m in _milestones)
        if (labels.containsKey(m.userCardId))
          _milestoneCalculator.compute(
            milestone: m,
            transactions: _transactions,
            cardLabel: labels[m.userCardId]!,
            now: now,
          ),
    ];
  }

  void _setState(ViewState newState) {
    _state = newState;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopListening();
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
