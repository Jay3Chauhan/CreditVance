import 'package:flutter/material.dart';

/// Centralized layout metrics and spacing for CardSage.
class AppDimensions {
  const AppDimensions._();

  // Spacing & Padding
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;

  // Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: p20, vertical: p16);
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: p20);
  static const EdgeInsets cardPadding = EdgeInsets.all(p20);

  // Border Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Card Aspect Ratio (ISO/IEC 7810 ID-1 standard)
  static const double cardAspectRatio = 1.586; // 340dp width : ~214dp height

  // Animation Durations
  static const Duration fastAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 350);
  static const Duration slowAnim = Duration(milliseconds: 600);
}
