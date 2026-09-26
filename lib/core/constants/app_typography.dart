import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography system for CardSage.
/// Uses Plus Jakarta Sans with fallbacks to system fonts.
class AppTypography {
  const AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.35,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        letterSpacing: 0.4,
        height: 1.45,
      );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        height: 1.3,
      );

  /// Specialized Monospace / Card Number typography
  static TextStyle get cardNumber => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 2.2,
        height: 1.2,
      );

  /// Currency & Returns numeric typography
  static TextStyle get currencyLarge => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  static TextStyle get currencyMedium => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );
}
