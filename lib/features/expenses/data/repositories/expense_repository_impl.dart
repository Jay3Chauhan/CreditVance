import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/bill_notice.dart';
import '../../domain/entities/card_milestone.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/raw_sms.dart';
import '../../domain/entities/sms_parse_result.dart';
import '../../domain/entities/sms_tracking_status.dart';
import '../../domain/entities/spend_category.dart';
import '../../domain/entities/tracked_card_ref.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/services/card_matcher.dart';
import '../datasources/expense_local_datasource.dart';
import '../datasources/expense_remote_datasource.dart';
import '../datasources/milestone_catalog_fallback.dart';
import '../datasources/sms_platform_datasource.dart';
import '../models/bill_notice_model.dart';
import '../models/card_transaction_model.dart';
import '../parsers/bank_sender_registry.dart';
import '../parsers/sms_transaction_parser.dart';

/// Top-level so it can run in a background isolate via [compute].
List<SmsParseOutcome> _parseInIsolate(List<RawSms> messages) => SmsTransactionParser().parseAll(messages);

/// Local-first implementation of [ExpenseRepository].
///
/// Data flow: native inbox query (bank senders only) → on-device parse in a
/// background isolate → dedupe/merge → local cache → sync queue → idempotent
/// batch upload of structured fields. The UI always reads local data, so the
/// feature keeps working offline or when the backend is not deployed.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final SmsPlatformDataSource _platform;
  final ExpenseLocalDataSource _local;
  final ExpenseRemoteDataSource _remote;
  final SmsTransactionParser _parser;
  final BankSenderRegistry _registry;
  final CardMatcher _matcher;
  final MilestoneCatalogFallback _milestoneFallback;

  ExpenseRepositoryImpl({
    required SmsPlatformDataSource platform,
    required ExpenseLocalDataSource local,
    required ExpenseRemoteDataSource remote,
    SmsTransactionParser? parser,
    BankSenderRegistry registry = const BankSenderRegistry(),
    CardMatcher matcher = const CardMatcher(),
    MilestoneCatalogFallback milestoneFallback = const MilestoneCatalogFallback(),
  })  : _platform = platform,
        _local = local,
        _remote = remote,
        _parser = parser ?? SmsTransactionParser(registry: registry),
        _registry = registry,
        _matcher = matcher,
        _milestoneFallback = milestoneFallback;

  /// First-run backfill window (CRED/axio-style ~6 months of history).
  static const Duration backfillWindow = Duration(days: 180);

  /// Re-read overlap so SMS written slightly out of order are not missed.
  static const Duration cursorOverlap = Duration(minutes: 2);
  static const int queryPageSize = 1500;
  static const int maxPagesPerScan = 6;
  static const int syncBatchSize = 100;

  static const String _txPrefix = 'tx:';
  static const String _billPrefix = 'bill:';
  static const String _delPrefix = 'del:';

  final Map<String, CardTransactionModel> _txns = {};
  final Map<String, BillNoticeModel> _bills = {};
  List<String> _queue = [];
  Set<String> _ignored = {};
  List<TrackedCardRef> _cards = const [];
  bool _loaded = false;
  Future<ApiResult<SmsScanReport>>? _scanInFlight;
  Future<ApiResult<ExpenseSyncReport>>? _syncInFlight;

  void _ensureLoaded() {
    if (_loaded) return;
    for (final t in _local.loadTransactions()) {
      _txns[t.id] = t;
    }
    for (final b in _local.loadBills()) {
      _bills[b.id] = b;
    }
    _queue = _local.loadSyncQueue();
    _ignored = _local.loadIgnored();
    _loaded = true;
  }

  Future<void> _persist() async {
    await _local.saveTransactions(_txns.values.toList());
    await _local.saveBills(_bills.values.toList());
    await _local.saveSyncQueue(_queue);
  }

  void _enqueue(String entry) {
    if (!_queue.contains(entry)) _queue.add(entry);
  }

  // ---------------------------------------------------------------------------
  // Permission & consent
  // ---------------------------------------------------------------------------

  @override
  bool get isSmsSupported => _platform.isSupported;

  SmsPermissionStatus _mapPermission(NativeSmsPermission p) {
    if (!_platform.isSupported) return SmsPermissionStatus.unsupported;
    if (p.granted) return SmsPermissionStatus.granted;
    if (_local.permissionAsked && !p.shouldShowRationale) return SmsPermissionStatus.permanentlyDenied;
    return SmsPermissionStatus.denied;
  }

  @override
  Future<SmsPermissionStatus> getSmsPermissionStatus() async => _mapPermission(await _platform.checkPermission());

  @override
  Future<SmsPermissionStatus> requestSmsPermission() async {
    if (!_platform.isSupported) return SmsPermissionStatus.unsupported;
    final result = await _platform.requestPermission();
    await _local.setPermissionAsked();
    return _mapPermission(result);
  }

  @override
  Future<void> openAppSettings() => _platform.openAppSettings();

  @override
  SmsConsent getConsent() => _local.loadConsent();

  @override
  Future<void> saveConsent(SmsConsent consent) async {
    await _local.saveConsent(consent.copyWith(isSyncedToServer: false));
    final result = await _remote.recordConsent(consent);
    if (result.isSuccess) await _local.saveConsent(consent.copyWith(isSyncedToServer: true));
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  List<CardTransaction> _sortedTransactions() =>
      _txns.values.toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Future<List<CardTransaction>> getCachedTransactions() async {
    _ensureLoaded();
    return _sortedTransactions();
  }

  @override
  Future<List<BillNotice>> getCachedBills() async {
    _ensureLoaded();
    return _bills.values.toList();
  }

  @override
  DateTime? get lastSyncedAt => _local.loadLastSynced();

  @override
  int get pendingSyncCount {
    _ensureLoaded();
    return _queue.length;
  }

  // ---------------------------------------------------------------------------
  // Ingestion
  // ---------------------------------------------------------------------------

  @override
  Future<ApiResult<SmsScanReport>> scanInbox({bool fullRescan = false}) {
    return _scanInFlight ??= _scan(fullRescan).whenComplete(() => _scanInFlight = null);
  }

  Future<ApiResult<SmsScanReport>> _scan(bool fullRescan) async {
    _ensureLoaded();
    if (!_platform.isSupported) return const ApiSuccess(SmsScanReport.none);
    if (!getConsent().isGranted) return const ApiSuccess(SmsScanReport.none);

    final permission = await _platform.checkPermission();
    if (!permission.granted) {
      return const ApiFailure('SMS permission is not granted. Enable it in Settings to track spends.');
    }

    final now = DateTime.now();
    final cursor = fullRescan ? null : _local.loadScanCursor();
    var since = cursor?.subtract(cursorOverlap) ?? now.subtract(backfillWindow);

    var scanned = 0;
    var newTxns = 0;
    var newBills = 0;
    final rejected = <SmsRejectReason, int>{};

    try {
      for (var page = 0; page < maxPagesPerScan; page++) {
        final messages = await _platform.queryInbox(
          since: since,
          senderKeys: _registry.allSenderKeys,
          limit: queryPageSize,
        );
        if (messages.isEmpty) break;
        scanned += messages.length;

        final outcomes = await compute(_parseInIsolate, messages);
        final (addedTxns, addedBills) = _merge(outcomes, rejected);
        newTxns += addedTxns;
        newBills += addedBills;

        final newest = messages.map((m) => m.receivedAt).reduce((x, y) => x.isAfter(y) ? x : y);
        await _local.saveScanCursor(newest);
        await _persist();
        if (messages.length < queryPageSize) break;
        since = newest;
      }
    } catch (e) {
      await _persist();
      return ApiFailure('Could not read SMS inbox: $e', originalError: e);
    }

    if (cursor == null && scanned == 0) await _local.saveScanCursor(now);
    return ApiSuccess(SmsScanReport(
      scanned: scanned,
      newTransactions: newTxns,
      newBills: newBills,
      rejected: rejected,
    ));
  }

  /// Merges parser outcomes; returns (new transactions, new bills).
  (int, int) _merge(List<SmsParseOutcome> outcomes, Map<SmsRejectReason, int> rejected) {
    var newTxns = 0;
    var newBills = 0;
    for (final outcome in outcomes) {
      switch (outcome) {
        case ParsedTransaction(:final transaction):
          if (_ignored.contains(transaction.id) || _txns.containsKey(transaction.id)) continue;
          if (_isNearDuplicate(transaction)) continue;
          final matched = transaction.copyWith(
            userCardId: _matcher.match(
              last4: transaction.cardLast4,
              bankName: transaction.bankName,
              cards: _cards,
            ),
          );
          _txns[matched.id] = CardTransactionModel.fromEntity(matched);
          _enqueue('$_txPrefix${matched.id}');
          newTxns++;
        case ParsedBillNotice(:final notice):
          if (_bills.containsKey(notice.id)) continue;
          final matched = notice.copyWith(
            userCardId: _matcher.match(last4: notice.cardLast4, bankName: notice.bankName, cards: _cards),
          );
          _bills[matched.id] = BillNoticeModel.fromEntity(matched);
          _enqueue('$_billPrefix${matched.id}');
          newBills++;
        case RejectedSms(:final reason):
          rejected[reason] = (rejected[reason] ?? 0) + 1;
      }
    }
    return (newTxns, newBills);
  }

  /// Catches the same alert delivered twice with slightly different text
  /// (e.g. once with and once without a reference number).
  bool _isNearDuplicate(CardTransaction t) {
    for (final e in _txns.values) {
      if (e.amount == t.amount &&
          e.type == t.type &&
          e.cardLast4 == t.cardLast4 &&
          e.bankCode == t.bankCode &&
          e.source != TransactionSource.manual &&
          e.occurredAt.difference(t.occurredAt).abs() <= const Duration(minutes: 2) &&
          e.merchantName == t.merchantName) {
        return true;
      }
    }
    return false;
  }

  @override
  Stream<DateTime> watchIncomingBankSms() => _platform.incomingBankSms(_registry.allSenderKeys);

  @override
  SmsParseOutcome previewPastedSms(String text) {
    return _parser.parse(RawSms(sender: '', body: text, receivedAt: DateTime.now(), origin: SmsOrigin.pasted));
  }

  @override
  Future<ApiResult<SmsParseOutcome>> importPastedSms(String text) async {
    _ensureLoaded();
    final outcome = previewPastedSms(text);
    if (outcome is ParsedTransaction && _txns.containsKey(outcome.transaction.id)) {
      return const ApiFailure('This transaction has already been added.');
    }
    _merge([outcome], {});
    await _persist();
    return ApiSuccess(outcome);
  }

  @override
  Future<ApiResult<CardTransaction>> addManualTransaction({
    required double amount,
    required String merchant,
    required SpendCategory category,
    required TransactionType type,
    required DateTime occurredAt,
    TrackedCardRef? card,
  }) async {
    _ensureLoaded();
    if (amount <= 0) return const ApiFailure('Enter an amount greater than zero.');
    final name = merchant.trim().isEmpty ? 'Manual entry' : merchant.trim();
    final id = 'm${SmsTransactionParser.dedupeHash('manual|${DateTime.now().microsecondsSinceEpoch}|$name|$amount')}'
        .substring(0, 32);
    final txn = CardTransactionModel(
      id: id,
      amount: amount,
      type: type,
      occurredAt: occurredAt,
      bankCode: 'MANUAL',
      bankName: card?.bankName ?? 'Card',
      cardLast4: card?.last4,
      userCardId: card?.userCardId,
      merchantRaw: name,
      merchantName: name,
      category: category,
      isCategoryOverridden: true,
      source: TransactionSource.manual,
      confidence: 1.0,
    );
    _txns[id] = txn;
    _enqueue('$_txPrefix$id');
    await _persist();
    return ApiSuccess(txn);
  }

  @override
  Future<ApiResult<CardTransaction>> updateCategory(String transactionId, SpendCategory category) async {
    _ensureLoaded();
    final existing = _txns[transactionId];
    if (existing == null) return const ApiFailure('Transaction not found', statusCode: 404);
    final updated = CardTransactionModel.fromEntity(
      existing.copyWith(category: category, isCategoryOverridden: true, isSynced: false),
    );
    _txns[transactionId] = updated;
    _enqueue('$_txPrefix$transactionId');
    await _persist();
    return ApiSuccess(updated);
  }

  @override
  Future<ApiResult<bool>> excludeTransaction(String transactionId) async {
    _ensureLoaded();
    final existing = _txns.remove(transactionId);
    if (existing == null) return const ApiFailure('Transaction not found', statusCode: 404);
    _ignored.add(transactionId);
    _queue.remove('$_txPrefix$transactionId');
    if (existing.isSynced) _enqueue('$_delPrefix$transactionId');
    await _local.saveIgnored(_ignored);
    await _persist();
    return const ApiSuccess(true);
  }

  @override
  Future<void> relinkCards(List<TrackedCardRef> cards) async {
    _ensureLoaded();
    _cards = cards;
    var changed = false;
    for (final entry in _txns.entries.toList()) {
      final t = entry.value;
      if (t.source == TransactionSource.manual) continue;
      final match = _matcher.match(last4: t.cardLast4, bankName: t.bankName, cards: cards);
      if (match != t.userCardId) {
        _txns[entry.key] = CardTransactionModel.fromEntity(
          t.copyWith(userCardId: match, clearUserCardId: match == null, isSynced: false),
        );
        _enqueue('$_txPrefix${entry.key}');
        changed = true;
      }
    }
    for (final entry in _bills.entries.toList()) {
      final b = entry.value;
      final match = _matcher.match(last4: b.cardLast4, bankName: b.bankName, cards: cards);
      if (match != null && match != b.userCardId) {
        _bills[entry.key] = BillNoticeModel.fromEntity(b.copyWith(userCardId: match));
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  static ExpenseSyncStatus _statusFor(int? statusCode) {
    if (statusCode == null) return ExpenseSyncStatus.offline;
    if (statusCode == 401 || statusCode == 403) return ExpenseSyncStatus.signedOut;
    if (statusCode == 404) return ExpenseSyncStatus.unavailable;
    return ExpenseSyncStatus.serverError;
  }

  @override
  Future<ApiResult<ExpenseSyncReport>> syncPending() {
    return _syncInFlight ??= _sync().whenComplete(() => _syncInFlight = null);
  }

  Future<ApiResult<ExpenseSyncReport>> _sync() async {
    _ensureLoaded();
    if (!await _remote.isOnline) {
      return ApiSuccess(ExpenseSyncReport(status: ExpenseSyncStatus.offline, uploaded: 0, pending: _queue.length));
    }

    if (_local.pendingRemoteErase) {
      final erase = await _remote.deleteAllData();
      if (erase.isSuccess) await _local.setPendingRemoteErase(false);
    }

    final consent = getConsent();
    if (consent.status != SmsConsentStatus.notAsked && !consent.isSyncedToServer) {
      final recorded = await _remote.recordConsent(consent);
      if (recorded.isSuccess) await _local.saveConsent(consent.copyWith(isSyncedToServer: true));
    }

    // Deletions first so a re-added record is never shadowed by a stale delete.
    for (final entry in _queue.where((e) => e.startsWith(_delPrefix)).toList()) {
      final result = await _remote.deleteTransaction(entry.substring(_delPrefix.length));
      if (result.isSuccess || (result as ApiFailure).statusCode == 404) _queue.remove(entry);
    }

    var uploaded = 0;
    final pendingUploads = _queue.where((e) => !e.startsWith(_delPrefix)).toList();
    for (var i = 0; i < pendingUploads.length; i += syncBatchSize) {
      final chunk = pendingUploads.sublist(i, (i + syncBatchSize).clamp(0, pendingUploads.length));
      final txns = <CardTransactionModel>[];
      final bills = <BillNoticeModel>[];
      for (final entry in chunk) {
        if (entry.startsWith(_txPrefix)) {
          final t = _txns[entry.substring(_txPrefix.length)];
          if (t != null) txns.add(t);
        } else if (entry.startsWith(_billPrefix)) {
          final b = _bills[entry.substring(_billPrefix.length)];
          if (b != null) bills.add(b);
        }
      }
      // Entries whose record no longer exists are simply dropped.
      _queue.removeWhere((e) => chunk.contains(e) && !_hasRecord(e));
      if (txns.isEmpty && bills.isEmpty) continue;

      final result = await _remote.uploadBatch(transactions: txns, bills: bills);
      if (result case ApiFailure(:final statusCode, :final message)) {
        await _persist();
        return ApiSuccess(ExpenseSyncReport(
          status: _statusFor(statusCode),
          uploaded: uploaded,
          pending: _queue.length,
          message: message,
        ));
      }

      final body = result.dataOrNull!;
      final acked = body.acknowledged.isEmpty ? {...txns.map((t) => t.id), ...bills.map((b) => b.id)} : body.acknowledged;
      for (final enrichment in body.enrichments) {
        final t = _txns[enrichment.dedupeHash];
        if (t == null || t.isCategoryOverridden) continue;
        _txns[t.id] = CardTransactionModel.fromEntity(
          t.copyWith(merchantName: enrichment.merchantName, category: enrichment.category),
        );
      }
      for (final hash in acked) {
        final t = _txns[hash];
        if (t != null) _txns[hash] = CardTransactionModel.fromEntity(t.copyWith(isSynced: true));
        _queue.remove('$_txPrefix$hash');
        _queue.remove('$_billPrefix$hash');
      }
      uploaded += acked.length;
    }

    final now = DateTime.now();
    await _local.saveLastSynced(now);
    await _persist();
    return ApiSuccess(ExpenseSyncReport(status: ExpenseSyncStatus.synced, uploaded: uploaded, pending: _queue.length));
  }

  bool _hasRecord(String entry) {
    if (entry.startsWith(_txPrefix)) return _txns.containsKey(entry.substring(_txPrefix.length));
    if (entry.startsWith(_billPrefix)) return _bills.containsKey(entry.substring(_billPrefix.length));
    return true;
  }

  // ---------------------------------------------------------------------------
  // Milestones & erasure
  // ---------------------------------------------------------------------------

  @override
  Future<ApiResult<List<CardMilestone>>> getMilestones(List<TrackedCardRef> cards) async {
    final remote = await _remote.fetchMilestones();
    if (remote.isSuccess && (remote.dataOrNull?.isNotEmpty ?? false)) return remote;
    return ApiSuccess(_milestoneFallback.milestonesFor(cards));
  }

  @override
  Future<ApiResult<bool>> deleteAllData() async {
    await clearLocalData();
    final withdrawn = SmsConsent(status: SmsConsentStatus.withdrawn, decidedAt: DateTime.now());
    await _local.saveConsent(withdrawn);
    final erase = await _remote.deleteAllData();
    await _local.setPendingRemoteErase(!erase.isSuccess);
    final recorded = await _remote.recordConsent(withdrawn);
    if (recorded.isSuccess) await _local.saveConsent(withdrawn.copyWith(isSyncedToServer: true));
    return const ApiSuccess(true);
  }

  @override
  Future<void> clearLocalData() async {
    _txns.clear();
    _bills.clear();
    _queue = [];
    _ignored = {};
    _loaded = true;
    await _local.clearAll();
  }
}
