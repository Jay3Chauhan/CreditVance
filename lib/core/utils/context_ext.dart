import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_palette.dart';

/// Window size classes used for responsive layouts.
enum WindowSize { compact, medium, expanded }

extension AppContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  TextTheme get text => Theme.of(this).textTheme;

  double get screenWidth => MediaQuery.sizeOf(this).width;

  WindowSize get windowSize {
    final w = screenWidth;
    if (w >= AppDimensions.expandedMin) return WindowSize.expanded;
    if (w >= AppDimensions.compactMax) return WindowSize.medium;
    return WindowSize.compact;
  }

  bool get isCompact => windowSize == WindowSize.compact;

  /// Bottom space scroll views need so content clears the floating nav bar.
  double get navClearance => isCompact ? 92 + MediaQuery.paddingOf(this).bottom : AppDimensions.p32;

  /// Horizontal padding that centers content on tablets / desktop.
  double gutter({double maxWidth = AppDimensions.contentMaxWidth}) {
    final w = screenWidth;
    if (w <= maxWidth + AppDimensions.p32) return AppDimensions.p16;
    return (w - maxWidth) / 2;
  }
}
