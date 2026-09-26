import 'package:flutter/material.dart';

/// Spacing, radii, motion and layout tokens for CreditVance.
class AppDimensions {
  const AppDimensions._();

  // Spacing scale
  static const double p2 = 2.0;
  static const double p4 = 4.0;
  static const double p6 = 6.0;
  static const double p8 = 8.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p14 = 14.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: p16);
  static const EdgeInsets cardPadding = EdgeInsets.all(p14);

  // Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Component sizes
  static const double buttonHeight = 48.0;
  static const double buttonHeightSm = 38.0;
  static const double chipHeight = 34.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double navBarHeight = 64.0;
  static const double searchBarHeight = 44.0;

  /// ISO/IEC 7810 ID-1 card ratio.
  static const double cardAspectRatio = 1.586;

  // Responsive breakpoints
  static const double compactMax = 600;
  static const double expandedMin = 1024;
  static const double contentMaxWidth = 760;
  static const double wideContentMaxWidth = 1180;

  // Motion
  static const Duration fastAnim = Duration(milliseconds: 180);
  static const Duration mediumAnim = Duration(milliseconds: 320);
  static const Duration slowAnim = Duration(milliseconds: 560);
  static const Duration staggerStep = Duration(milliseconds: 40);
  static const Duration debounce = Duration(milliseconds: 350);
}
