import 'package:flutter/services.dart';

/// Haptic feedback triggers. Respects the user's haptics setting.
class HapticsHelper {
  const HapticsHelper._();

  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void error() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
