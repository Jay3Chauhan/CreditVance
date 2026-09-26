import 'dart:async';

import '../platform/secure_platform.dart';

/// Copies sensitive values and guarantees they are wiped after a timeout.
///
/// The wipe is scheduled natively (works in background on Android 10+ where
/// apps can no longer read the clipboard) with a Dart timer as a backstop.
class ClipboardHelper {
  ClipboardHelper._();
  static final ClipboardHelper instance = ClipboardHelper._();

  Timer? _backstop;

  Future<void> copyWithAutoClear(String text, {Duration duration = const Duration(seconds: 30)}) async {
    await SecurePlatform.copySensitive(text, clearAfter: duration);
    _backstop?.cancel();
    _backstop = Timer(duration + const Duration(seconds: 1), SecurePlatform.clearClipboard);
  }

  Future<void> clearNow() async {
    _backstop?.cancel();
    await SecurePlatform.clearClipboard();
  }
}
