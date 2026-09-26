import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/platform/secure_platform.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../domain/app_settings.dart';

/// Holds [AppSettings] and applies side effects (haptics, screenshot guard).
class SettingsProvider extends ChangeNotifier {
  final LocalCacheService _cache;

  SettingsProvider(this._cache) : _settings = _load(_cache) {
    _applySideEffects();
  }

  AppSettings _settings;
  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;

  static AppSettings _load(LocalCacheService cache) {
    final raw = cache.getSettings();
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  void setThemeMode(ThemeMode mode) => _update(_settings.copyWith(themeMode: mode));

  void setClipboardSeconds(int seconds) => _update(_settings.copyWith(clipboardClearSeconds: seconds));

  void setRevealSeconds(int seconds) => _update(_settings.copyWith(revealSeconds: seconds));

  void setAppLock(bool enabled) => _update(_settings.copyWith(appLockEnabled: enabled));

  void setBlockScreenshots(bool enabled) => _update(_settings.copyWith(blockScreenshots: enabled));

  void setHaptics(bool enabled) => _update(_settings.copyWith(hapticsEnabled: enabled));

  void _update(AppSettings next) {
    _settings = next;
    _applySideEffects();
    notifyListeners();
    _cache.setSettings(jsonEncode(next.toJson()));
  }

  void _applySideEffects() {
    HapticsHelper.enabled = _settings.hapticsEnabled;
    SecurePlatform.setScreenshotsBlocked(_settings.blockScreenshots);
  }
}
