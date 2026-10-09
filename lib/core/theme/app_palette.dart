import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Theme-aware semantic colors. Read via `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceHigh;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color info;
  final Color warning;
  final Color danger;
  final Color shadow;

  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceHigh,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  bool get isDark => brightness == Brightness.dark;

  /// Soft tinted fill for chips, icon halos and selected states.
  Color tint(Color color, [double amount = 0.12]) => color.withValues(alpha: amount);

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    canvas: AppColors.darkCanvas,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurfaceAlt,
    surfaceHigh: AppColors.darkSurfaceHigh,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    accent: AppColors.gold,
    onAccent: Color(0xFF17120A),
    success: AppColors.emerald,
    info: AppColors.sapphire,
    warning: AppColors.amber,
    danger: AppColors.ruby,
    shadow: AppColors.shadowDark,
  );

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    canvas: AppColors.lightCanvas,
    surface: AppColors.lightSurface,
    surfaceAlt: AppColors.lightSurfaceAlt,
    surfaceHigh: AppColors.lightSurfaceHigh,
    border: AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    accent: AppColors.lightGold,
    onAccent: AppColors.white,
    success: AppColors.lightEmerald,
    info: AppColors.lightSapphire,
    warning: AppColors.lightAmber,
    danger: AppColors.lightRuby,
    shadow: AppColors.shadowLight,
  );

  @override
  AppPalette copyWith({Color? accent}) => AppPalette(
        brightness: brightness,
        canvas: canvas,
        surface: surface,
        surfaceAlt: surfaceAlt,
        surfaceHigh: surfaceHigh,
        border: border,
        borderStrong: borderStrong,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        accent: accent ?? this.accent,
        onAccent: onAccent,
        success: success,
        info: info,
        warning: warning,
        danger: danger,
        shadow: shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      success: l(success, other.success),
      info: l(info, other.info),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      shadow: l(shadow, other.shadow),
    );
  }
}
