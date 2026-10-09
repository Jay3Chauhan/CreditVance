import 'dart:convert';

import '../../../../core/storage/local_cache_service.dart';
import '../../domain/entities/sms_tracking_status.dart';
import '../models/bill_notice_model.dart';
import '../models/card_transaction_model.dart';
import '../models/sms_consent_model.dart';

/// Local persistence for parsed expense data on top of [LocalCacheService].
///
/// Stores structured fields only; raw SMS bodies are never written to disk.
/// Retention is bounded so SharedPreferences stays small.
class ExpenseLocalDataSource {
  final LocalCacheService _cache;

  ExpenseLocalDataSource(this._cache);

  /// Keep at most ~13 months of history on device.
  static const Duration retention = Duration(days: 400);
  static const int maxTransactions = 5000;
  static const int maxBills = 200;

  /// Loads cached transactions (newest first); corrupt cache yields an empty list.
  List<CardTransactionModel> loadTransactions() {
    final raw = _cache.getExpenseTransactions();
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CardTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists transactions after applying retention and size caps.
  Future<void> saveTransactions(List<CardTransactionModel> txns) async {
    final cutoff = DateTime.now().subtract(retention);
    final kept = txns.where((t) => t.occurredAt.isAfter(cutoff)).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final capped = kept.length > maxTransactions ? kept.sublist(0, maxTransactions) : kept;
    await _cache.setExpenseTransactions(jsonEncode([for (final t in capped) t.toJson()]));
  }

  List<BillNoticeModel> loadBills() {
    final raw = _cache.getExpenseBills();
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => BillNoticeModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBills(List<BillNoticeModel> bills) async {
    final sorted = [...bills]..sort((a, b) => b.noticedAt.compareTo(a.noticedAt));
    final capped = sorted.length > maxBills ? sorted.sublist(0, maxBills) : sorted;
    await _cache.setExpenseBills(jsonEncode([for (final b in capped) b.toJson()]));
  }

  List<String> loadSyncQueue() => List<String>.of(_cache.getExpenseSyncQueue());

  Future<void> saveSyncQueue(List<String> queue) => _cache.setExpenseSyncQueue(queue.toSet().toList());

  Set<String> loadIgnored() => _cache.getExpenseIgnoredHashes().toSet();

  Future<void> saveIgnored(Set<String> hashes) => _cache.setExpenseIgnoredHashes(hashes.toList());

  SmsConsent loadConsent() {
    final raw = _cache.getExpenseConsent();
    if (raw == null || raw.isEmpty) return SmsConsent.initial;
    try {
      return SmsConsentModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SmsConsent.initial;
    }
  }

  Future<void> saveConsent(SmsConsent consent) =>
      _cache.setExpenseConsent(jsonEncode(SmsConsentModel.fromEntity(consent).toJson()));

  DateTime? loadScanCursor() {
    final ms = _cache.getExpenseScanCursor();
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveScanCursor(DateTime cursor) => _cache.setExpenseScanCursor(cursor.millisecondsSinceEpoch);

  DateTime? loadLastSynced() {
    final ms = _cache.getExpenseLastSynced();
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastSynced(DateTime at) => _cache.setExpenseLastSynced(at.millisecondsSinceEpoch);

  bool get pendingRemoteErase => _cache.getExpensePendingErase();

  Future<void> setPendingRemoteErase(bool pending) => _cache.setExpensePendingErase(pending);

  bool get permissionAsked => _cache.getExpensePermissionAsked();

  Future<void> setPermissionAsked() => _cache.setExpensePermissionAsked(true);

  /// Removes every SMS-derived record, cursor, queue and consent.
  Future<void> clearAll() => _cache.clearExpenseData();
}
