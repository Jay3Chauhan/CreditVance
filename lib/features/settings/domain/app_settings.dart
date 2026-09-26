import 'package:flutter/material.dart';

/// User-controlled app preferences. Persisted locally only.
@immutable
class AppSettings {
  final ThemeMode themeMode;
  final int clipboardClearSeconds;
  final int revealSeconds;
  final bool appLockEnabled;
  final bool blockScreenshots;
  final bool hapticsEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.clipboardClearSeconds = 30,
    this.revealSeconds = 30,
    this.appLockEnabled = false,
    this.blockScreenshots = true,
    this.hapticsEnabled = true,
  });

  static const List<int> clipboardOptions = [15, 30, 60, 120];
  static const List<int> revealOptions = [15, 30, 60];

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? clipboardClearSeconds,
    int? revealSeconds,
    bool? appLockEnabled,
    bool? blockScreenshots,
    bool? hapticsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      clipboardClearSeconds: clipboardClearSeconds ?? this.clipboardClearSeconds,
      revealSeconds: revealSeconds ?? this.revealSeconds,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == json['theme_mode'],
        orElse: () => ThemeMode.system,
      ),
      clipboardClearSeconds: json['clipboard_clear_seconds'] as int? ?? 30,
      revealSeconds: json['reveal_seconds'] as int? ?? 30,
      appLockEnabled: json['app_lock_enabled'] as bool? ?? false,
      blockScreenshots: json['block_screenshots'] as bool? ?? true,
      hapticsEnabled: json['haptics_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme_mode': themeMode.name,
        'clipboard_clear_seconds': clipboardClearSeconds,
        'reveal_seconds': revealSeconds,
        'app_lock_enabled': appLockEnabled,
        'block_screenshots': blockScreenshots,
        'haptics_enabled': hapticsEnabled,
      };
}
