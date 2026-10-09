import 'package:shared_preferences/shared_preferences.dart';

/// Local Cache Service using SharedPreferences for sub-second offline loading.
class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  static const String _keyAuthToken = 'cs_auth_token';
  static const String _keyUserProfile = 'cs_user_profile';
  static const String _keyCatalogCache = 'cs_catalog_cache_v2';
  static const String _keyBanksCache = 'cs_banks_cache';
  static const String _keyCategoriesCache = 'cs_categories_cache';
  static const String _keyLastCacheTime = 'cs_last_cache_time';

  // SMS expense tracking (structured, parsed fields only — never raw SMS bodies)
  static const String _keyExpenseTransactions = 'cs_expense_txns_v1';
  static const String _keyExpenseBills = 'cs_expense_bills_v1';
  static const String _keyExpenseSyncQueue = 'cs_expense_sync_queue_v1';
  static const String _keyExpenseIgnored = 'cs_expense_ignored_v1';
  static const String _keyExpenseConsent = 'cs_expense_consent_v1';
  static const String _keyExpenseScanCursor = 'cs_expense_scan_cursor_ms';
  static const String _keyExpenseLastSynced = 'cs_expense_last_synced_ms';
  static const String _keyExpensePendingErase = 'cs_expense_pending_erase';
  static const String _keyExpensePermissionAsked = 'cs_expense_permission_asked';

  // Auth Token
  String? getAuthToken() => _prefs.getString(_keyAuthToken);

  Future<bool> setAuthToken(String token) => _prefs.setString(_keyAuthToken, token);

  Future<bool> clearAuthToken() => _prefs.remove(_keyAuthToken);

  // User Profile
  String? getUserProfile() => _prefs.getString(_keyUserProfile);

  Future<bool> setUserProfile(String jsonStr) => _prefs.setString(_keyUserProfile, jsonStr);

  // Catalog Cache
  String? getCatalogCache() => _prefs.getString(_keyCatalogCache);

  Future<bool> setCatalogCache(String jsonStr) {
    _prefs.setInt(_keyLastCacheTime, DateTime.now().millisecondsSinceEpoch);
    return _prefs.setString(_keyCatalogCache, jsonStr);
  }

  // Banks Cache
  String? getBanksCache() => _prefs.getString(_keyBanksCache);

  Future<bool> setBanksCache(String jsonStr) => _prefs.setString(_keyBanksCache, jsonStr);

  // Categories Cache
  String? getCategoriesCache() => _prefs.getString(_keyCategoriesCache);

  Future<bool> setCategoriesCache(String jsonStr) => _prefs.setString(_keyCategoriesCache, jsonStr);

  // Parsed card transactions (JSON array)
  String? getExpenseTransactions() => _prefs.getString(_keyExpenseTransactions);

  Future<bool> setExpenseTransactions(String jsonStr) => _prefs.setString(_keyExpenseTransactions, jsonStr);

  // Parsed bill / statement notices (JSON array)
  String? getExpenseBills() => _prefs.getString(_keyExpenseBills);

  Future<bool> setExpenseBills(String jsonStr) => _prefs.setString(_keyExpenseBills, jsonStr);

  // Offline sync queue of dedupe hashes awaiting backend acknowledgement
  List<String> getExpenseSyncQueue() => _prefs.getStringList(_keyExpenseSyncQueue) ?? const [];

  Future<bool> setExpenseSyncQueue(List<String> hashes) => _prefs.setStringList(_keyExpenseSyncQueue, hashes);

  // Dedupe hashes the user marked as "not a transaction" so rescans skip them
  List<String> getExpenseIgnoredHashes() => _prefs.getStringList(_keyExpenseIgnored) ?? const [];

  Future<bool> setExpenseIgnoredHashes(List<String> hashes) => _prefs.setStringList(_keyExpenseIgnored, hashes);

  // SMS tracking consent record (JSON object)
  String? getExpenseConsent() => _prefs.getString(_keyExpenseConsent);

  Future<bool> setExpenseConsent(String jsonStr) => _prefs.setString(_keyExpenseConsent, jsonStr);

  // Incremental inbox scan cursor (epoch millis of newest processed SMS)
  int? getExpenseScanCursor() => _prefs.getInt(_keyExpenseScanCursor);

  Future<bool> setExpenseScanCursor(int epochMillis) => _prefs.setInt(_keyExpenseScanCursor, epochMillis);

  // Last successful backend sync (epoch millis)
  int? getExpenseLastSynced() => _prefs.getInt(_keyExpenseLastSynced);

  Future<bool> setExpenseLastSynced(int epochMillis) => _prefs.setInt(_keyExpenseLastSynced, epochMillis);

  // Remote erasure requested while offline; retried on next sync
  bool getExpensePendingErase() => _prefs.getBool(_keyExpensePendingErase) ?? false;

  Future<bool> setExpensePendingErase(bool pending) => _prefs.setBool(_keyExpensePendingErase, pending);

  // Whether the runtime SMS permission dialog has been shown at least once
  bool getExpensePermissionAsked() => _prefs.getBool(_keyExpensePermissionAsked) ?? false;

  Future<bool> setExpensePermissionAsked(bool asked) => _prefs.setBool(_keyExpensePermissionAsked, asked);

  /// Wipes every locally stored SMS-derived record, cursor and queue.
  /// Consent is cleared too so the prominent disclosure is shown again.
  Future<void> clearExpenseData() async {
    await _prefs.remove(_keyExpenseTransactions);
    await _prefs.remove(_keyExpenseBills);
    await _prefs.remove(_keyExpenseSyncQueue);
    await _prefs.remove(_keyExpenseIgnored);
    await _prefs.remove(_keyExpenseConsent);
    await _prefs.remove(_keyExpenseScanCursor);
    await _prefs.remove(_keyExpenseLastSynced);
  }

  // Clear all cached state
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
