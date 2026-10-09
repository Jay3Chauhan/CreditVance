import '../../../../core/network/api_result.dart';
import '../entities/bill_notice.dart';
import '../entities/card_milestone.dart';
import '../entities/card_transaction.dart';
import '../entities/sms_parse_result.dart';
import '../entities/sms_tracking_status.dart';
import '../entities/spend_category.dart';
import '../entities/tracked_card_ref.dart';

/// Contract for SMS-based card expense tracking.
///
/// Implementations parse SMS strictly on-device and only ever send structured
/// fields (last 4 digits, amount, merchant, category, timestamps, dedupe hash)
/// to the backend. Raw SMS bodies, full PANs, CVVs and expiry never leave the phone.
abstract class ExpenseRepository {
  /// Whether this platform can read SMS (Android only).
  bool get isSmsSupported;

  /// Current READ_SMS / RECEIVE_SMS runtime permission state.
  Future<SmsPermissionStatus> getSmsPermissionStatus();

  /// Shows the system permission dialog (call only after prominent disclosure).
  Future<SmsPermissionStatus> requestSmsPermission();

  /// Opens the app's system settings page (for permanently denied permission).
  Future<void> openAppSettings();

  /// Locally persisted consent record.
  SmsConsent getConsent();

  /// Persists [consent] and records it on the backend (best effort, retried on sync).
  Future<void> saveConsent(SmsConsent consent);

  /// Cached transactions, newest first.
  Future<List<CardTransaction>> getCachedTransactions();

  /// Cached statement / bill notices.
  Future<List<BillNotice>> getCachedBills();

  /// Reads new bank SMS since the last cursor, parses them on-device, dedupes
  /// and persists. [fullRescan] re-reads the default 180-day backfill window.
  Future<ApiResult<SmsScanReport>> scanInbox({bool fullRescan = false});

  /// Emits whenever a new bank SMS arrives while the app is running. The event
  /// carries no SMS content; callers should follow up with [scanInbox].
  Stream<DateTime> watchIncomingBankSms();

  /// Uploads queued structured records in idempotent batches.
  /// Degraded states (offline, 401, 404, 5xx) are reported via [ExpenseSyncReport.status].
  Future<ApiResult<ExpenseSyncReport>> syncPending();

  /// Last successful backend sync.
  DateTime? get lastSyncedAt;

  /// Number of records waiting to be uploaded.
  int get pendingSyncCount;

  /// Adds a manually entered transaction (iOS / no-permission fallback).
  Future<ApiResult<CardTransaction>> addManualTransaction({
    required double amount,
    required String merchant,
    required SpendCategory category,
    required TransactionType type,
    required DateTime occurredAt,
    TrackedCardRef? card,
  });

  /// Parses a pasted SMS on-device without saving it (live preview).
  SmsParseOutcome previewPastedSms(String text);

  /// Parses and saves a pasted SMS when it is a transaction or bill notice.
  Future<ApiResult<SmsParseOutcome>> importPastedSms(String text);

  /// User correction of a transaction category (also sent as backend feedback).
  Future<ApiResult<CardTransaction>> updateCategory(String transactionId, SpendCategory category);

  /// Removes a mis-parsed record and prevents rescans from re-adding it.
  Future<ApiResult<bool>> excludeTransaction(String transactionId);

  /// Re-matches cached records to saved cards by last 4 digits.
  Future<void> relinkCards(List<TrackedCardRef> cards);

  /// Spend milestones for the user's cards (backend first, catalog fallback).
  Future<ApiResult<List<CardMilestone>>> getMilestones(List<TrackedCardRef> cards);

  /// Erases all SMS-derived data locally and on the backend and withdraws consent.
  Future<ApiResult<bool>> deleteAllData();

  /// Clears local SMS-derived data only (e.g. on sign-out).
  Future<void> clearLocalData();
}
