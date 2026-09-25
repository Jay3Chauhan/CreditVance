import 'package:flutter/services.dart';

/// Haptic feedback triggers for tactile fintech micro-interactions.
class HapticsHelper {
  const HapticsHelper._();

  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void error() {
    HapticFeedback.vibrate();
  }

  static void success() {
    HapticFeedback.lightImpact();
  }
}
