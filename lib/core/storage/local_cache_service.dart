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

  // Clear all cached state
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
