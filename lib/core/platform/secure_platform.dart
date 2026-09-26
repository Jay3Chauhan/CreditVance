import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the native secure-clipboard and screen-privacy APIs
/// implemented in `MainActivity.kt` (Android) and `AppDelegate.swift` (iOS).
///
/// Every call degrades gracefully to Flutter's [Clipboard] when the native
/// side is unavailable (web, tests, older builds).
class SecurePlatform {
  const SecurePlatform._();

  static const MethodChannel _channel = MethodChannel('creditvance/secure');

  static bool get _isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Copies [text] marked as sensitive and schedules a native clear.
  static Future<void> copySensitive(String text, {required Duration clearAfter}) async {
    if (_isMobile) {
      try {
        await _channel.invokeMethod<void>('copySensitive', {
          'text': text,
          'clearAfterMs': clearAfter.inMilliseconds,
        });
        return;
      } on MissingPluginException {
        // Fall through to Flutter clipboard.
      } on PlatformException {
        // Fall through to Flutter clipboard.
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Clears the clipboard immediately. Does not need to read it first, so it
  /// works while the app is in the background on Android 10+.
  static Future<void> clearClipboard() async {
    if (_isMobile) {
      try {
        await _channel.invokeMethod<void>('clearClipboard');
        return;
      } on MissingPluginException {
        // Fall through.
      } on PlatformException {
        // Fall through.
      }
    }
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// Blocks screenshots / screen recording and hides content in the
  /// recent-apps switcher (Android FLAG_SECURE).
  static Future<void> setScreenshotsBlocked(bool blocked) async {
    if (!_isMobile || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecureScreen', {'enabled': blocked});
    } on MissingPluginException {
      // Not available (tests / older builds).
    } on PlatformException {
      // Ignore.
    }
  }
}
