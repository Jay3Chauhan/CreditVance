import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local persistence (SharedPreferences).
///
/// Never store PAN, CVV or expiry here — those belong in [SecureVaultService].
class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  static const String _keyAuthToken = 'cs_auth_token';
  static const String _keyGuest = 'cs_is_guest';
  static const String _keyUserProfile = 'cs_user_profile';
  static const String _keyCatalogCache = 'cs_catalog_cache_v3';
  static const String _keyCatalogCacheTime = 'cs_catalog_cache_time_v3';
  static const String _keyBanksCache = 'cs_banks_cache_v2';
  static const String _keyCategoriesCache = 'cs_categories_cache_v2';
  static const String _keyWalletCards = 'cs_wallet_cards_v1';
  static const String _keyWalletOrder = 'cs_wallet_order_v1';
  static const String _keySettings = 'cs_settings_v1';
  static const String _keyOnboarded = 'cs_onboarded_v1';

  static const Duration catalogTtl = Duration(hours: 6);

  // Session
  String? getAuthToken() => _prefs.getString(_keyAuthToken);
  Future<bool> setAuthToken(String token) => _prefs.setString(_keyAuthToken, token);
  Future<bool> clearAuthToken() => _prefs.remove(_keyAuthToken);

  bool get isGuest => _prefs.getBool(_keyGuest) ?? false;
  Future<bool> setGuest(bool value) => _prefs.setBool(_keyGuest, value);

  String? getUserProfile() => _prefs.getString(_keyUserProfile);
  Future<bool> setUserProfile(String jsonStr) => _prefs.setString(_keyUserProfile, jsonStr);
  Future<bool> clearUserProfile() => _prefs.remove(_keyUserProfile);

  bool get hasOnboarded => _prefs.getBool(_keyOnboarded) ?? false;
  Future<bool> setOnboarded() => _prefs.setBool(_keyOnboarded, true);

  // Catalog (first page for default filters only)
  String? getCatalogCache({bool ignoreTtl = false}) {
    final savedAt = _prefs.getInt(_keyCatalogCacheTime);
    if (savedAt == null) return null;
    final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
    if (!ignoreTtl && age > catalogTtl) return null;
    return _prefs.getString(_keyCatalogCache);
  }

  Future<bool> setCatalogCache(String jsonStr) async {
    await _prefs.setInt(_keyCatalogCacheTime, DateTime.now().millisecondsSinceEpoch);
    return _prefs.setString(_keyCatalogCache, jsonStr);
  }

  String? getBanksCache() => _prefs.getString(_keyBanksCache);
  Future<bool> setBanksCache(String jsonStr) => _prefs.setString(_keyBanksCache, jsonStr);

  String? getCategoriesCache() => _prefs.getString(_keyCategoriesCache);
  Future<bool> setCategoriesCache(String jsonStr) => _prefs.setString(_keyCategoriesCache, jsonStr);

  Future<void> clearCatalogCaches() async {
    await _prefs.remove(_keyCatalogCache);
    await _prefs.remove(_keyCatalogCacheTime);
    await _prefs.remove(_keyBanksCache);
    await _prefs.remove(_keyCategoriesCache);
  }

  // Wallet metadata (nickname, last 4, bank, card model — no secrets)
  String? getWalletCards() => _prefs.getString(_keyWalletCards);
  Future<bool> setWalletCards(String jsonStr) => _prefs.setString(_keyWalletCards, jsonStr);

  List<int> getWalletOrder() =>
      (_prefs.getStringList(_keyWalletOrder) ?? const []).map(int.tryParse).whereType<int>().toList();
  Future<bool> setWalletOrder(List<int> ids) =>
      _prefs.setStringList(_keyWalletOrder, ids.map((e) => e.toString()).toList());

  // App settings
  String? getSettings() => _prefs.getString(_keySettings);
  Future<bool> setSettings(String jsonStr) => _prefs.setString(_keySettings, jsonStr);

  /// Clears the signed-in session and wallet metadata but keeps app settings
  /// (theme, security preferences) and the public catalog cache.
  Future<void> clearSession() async {
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyGuest);
    await _prefs.remove(_keyUserProfile);
    await _prefs.remove(_keyWalletCards);
    await _prefs.remove(_keyWalletOrder);
  }
}
