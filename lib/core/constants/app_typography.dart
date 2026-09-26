import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for CreditVance.
///
/// Sizes are deliberately compact (fintech density). Colors are applied by
/// [AppTheme] through the [TextTheme], so read styles via `context.text`.
class AppTypography {
  const AppTypography._();

  static TextStyle _sans(double size, FontWeight weight, {double spacing = 0, double height = 1.35}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
      );

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    return TextTheme(
      displayLarge: _sans(28, FontWeight.w700, spacing: -0.8, height: 1.15).copyWith(color: primary),
      displayMedium: _sans(24, FontWeight.w700, spacing: -0.6, height: 1.2).copyWith(color: primary),
      displaySmall: _sans(21, FontWeight.w700, spacing: -0.5, height: 1.2).copyWith(color: primary),
      headlineLarge: _sans(19, FontWeight.w700, spacing: -0.4, height: 1.25).copyWith(color: primary),
      headlineMedium: _sans(17, FontWeight.w700, spacing: -0.3, height: 1.3).copyWith(color: primary),
      headlineSmall: _sans(15.5, FontWeight.w600, spacing: -0.2, height: 1.3).copyWith(color: primary),
      titleLarge: _sans(15, FontWeight.w600, spacing: -0.1).copyWith(color: primary),
      titleMedium: _sans(14, FontWeight.w600).copyWith(color: primary),
      titleSmall: _sans(13, FontWeight.w600).copyWith(color: primary),
      bodyLarge: _sans(14, FontWeight.w400, height: 1.5).copyWith(color: secondary),
      bodyMedium: _sans(13, FontWeight.w400, height: 1.45).copyWith(color: secondary),
      bodySmall: _sans(12, FontWeight.w400, height: 1.4).copyWith(color: tertiary),
      labelLarge: _sans(13, FontWeight.w600, spacing: 0.1).copyWith(color: primary),
      labelMedium: _sans(12, FontWeight.w600, spacing: 0.1).copyWith(color: secondary),
      labelSmall: _sans(10.5, FontWeight.w600, spacing: 0.5, height: 1.3).copyWith(color: tertiary),
    );
  }

  /// Tabular numerals for amounts, percentages and counters.
  static TextStyle numeric(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.4,
        height: 1.15,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Embossed-style PAN digits on rendered cards.
  static TextStyle cardNumber(double size, {Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: size * 0.14,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Tiny uppercase captions printed on cards ("VALID THRU").
  static TextStyle cardCaption({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 7.5,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.0,
        height: 1.2,
      );
}
