import 'dart:async';
import 'package:flutter/services.dart';

/// Clipboard utility with auto-clearing security timer.
class ClipboardHelper {
  ClipboardHelper._();
  static final ClipboardHelper instance = ClipboardHelper._();

  Timer? _autoClearTimer;

  /// Copies text to clipboard and starts a 30-second wipe countdown.
  Future<void> copyWithAutoClear(String text, {Duration duration = const Duration(seconds: 30)}) async {
    await Clipboard.setData(ClipboardData(text: text));

    _autoClearTimer?.cancel();
    _autoClearTimer = Timer(duration, () async {
      final currentData = await Clipboard.getData(Clipboard.kTextPlain);
      if (currentData?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  /// Cancels any scheduled wipe
  void cancelScheduledClear() {
    _autoClearTimer?.cancel();
  }
}
