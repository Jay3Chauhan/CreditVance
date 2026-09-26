import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import 'app_palette.dart';

/// Builds the light and dark [ThemeData] from a single [AppPalette].
class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme => _build(AppPalette.dark);
  static ThemeData get lightTheme => _build(AppPalette.light);

  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: const Color(0x00000000),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData _build(AppPalette p) {
    final text = AppTypography.textTheme(
      primary: p.textPrimary,
      secondary: p.textSecondary,
      tertiary: p.textTertiary,
    );

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.success,
      onSecondary: p.onAccent,
      tertiary: p.info,
      onTertiary: p.onAccent,
      error: p.danger,
      onError: p.onAccent,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.canvas,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceHigh,
      surfaceContainerHighest: p.surfaceHigh,
      outline: p.borderStrong,
      outlineVariant: p.border,
      shadow: p.shadow,
      inverseSurface: p.textPrimary,
      onInverseSurface: p.canvas,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: AppDimensions.roundedMd,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.canvas,
      textTheme: text,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        surfaceTintColor: const Color(0x00000000),
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
        iconTheme: IconThemeData(color: p.textPrimary, size: AppDimensions.iconMd),
        systemOverlayStyle: overlayFor(p.brightness),
      ),
      iconTheme: IconThemeData(color: p.textSecondary, size: AppDimensions.iconMd),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedLg,
          side: BorderSide(color: p.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: const Color(0x00000000),
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: const Color(0x00000000),
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedXl),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.accent, 1.4),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.4),
        hintStyle: text.bodyMedium?.copyWith(color: p.textTertiary),
        labelStyle: text.bodyMedium,
        errorStyle: text.labelSmall?.copyWith(color: p.danger, letterSpacing: 0),
        prefixIconColor: p.textTertiary,
        suffixIconColor: p.textTertiary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.tint(p.accent, 0.3),
        selectionHandleColor: p.accent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(64, AppDimensions.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedSm),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAccent : p.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.borderStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.surfaceHigh,
        thumbColor: p.accent,
        overlayColor: p.tint(p.accent, 0.16),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        valueIndicatorColor: p.textPrimary,
        valueIndicatorTextStyle: text.labelMedium?.copyWith(color: p.canvas),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceHigh,
        circularTrackColor: p.surfaceHigh,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.textPrimary, borderRadius: AppDimensions.roundedSm),
        textStyle: text.labelMedium?.copyWith(color: p.canvas),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.p14),
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: p.textSecondary,
        collapsedIconColor: p.textTertiary,
        textColor: p.textPrimary,
        collapsedTextColor: p.textPrimary,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppDimensions.p14),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimensions.p14,
          0,
          AppDimensions.p14,
          AppDimensions.p14,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedMd,
          side: BorderSide(color: p.border),
        ),
        textStyle: text.bodyMedium?.copyWith(color: p.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.canvas),
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.tint(p.accent, 0.16),
        selectedIconTheme: IconThemeData(color: p.accent, size: 22),
        unselectedIconTheme: IconThemeData(color: p.textTertiary, size: 22),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: p.accent),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: p.textTertiary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
          ),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.borderStrong),
        radius: const Radius.circular(8),
      ),
    );
  }
}
