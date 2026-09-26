import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_typography.dart';
import 'haptics_helper.dart';

enum AppToastType { success, error, info, warning }

/// Luxury Toast Notification Service — glassmorphic floating alerts with accent bar + progress.
/// Design: left accent bar | icon halo | title + subtitle | auto-dismiss progress bar.
class AppToast {
  const AppToast._();

  static void success(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticsHelper.light();
    _show(
      context: context,
      message: message,
      title: title ?? 'Success',
      type: AppToastType.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    HapticsHelper.error();
    _show(
      context: context,
      message: message,
      title: title ?? 'Error',
      type: AppToastType.error,
      duration: duration,
    );
  }

  static void info(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticsHelper.selection();
    _show(
      context: context,
      message: message,
      title: title ?? 'Notice',
      type: AppToastType.info,
      duration: duration,
    );
  }

  static void warning(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticsHelper.medium();
    _show(
      context: context,
      message: message,
      title: title ?? 'Warning',
      type: AppToastType.warning,
      duration: duration,
    );
  }

  static void _show({
    BuildContext? context,
    required String message,
    required String title,
    required AppToastType type,
    required Duration duration,
  }) {
    Color accentColor;
    IconData iconData;

    switch (type) {
      case AppToastType.success:
        accentColor = AppColors.emerald;
        iconData = AppIcons.check;
        break;
      case AppToastType.error:
        accentColor = AppColors.error;
        iconData = AppIcons.alertCircle;
        break;
      case AppToastType.warning:
        accentColor = AppColors.gold;
        iconData = AppIcons.alertCircle;
        break;
      case AppToastType.info:
        accentColor = AppColors.sapphire;
        iconData = AppIcons.info;
        break;
    }

    toastification.showCustom(
      context: context,
      autoCloseDuration: duration,
      alignment: Alignment.topCenter,
      builder: (ctx, holder) {
        return _LuxuryToastWidget(
          title: title,
          message: message,
          accentColor: accentColor,
          iconData: iconData,
          duration: duration,
          holder: holder,
        );
      },
    );
  }
}

/// Internal stateless toast widget.
/// Progress bar driven by TweenAnimationBuilder (no setState needed).
class _LuxuryToastWidget extends StatelessWidget {
  final String title;
  final String message;
  final Color accentColor;
  final IconData iconData;
  final Duration duration;
  final ToastificationItem holder;

  const _LuxuryToastWidget({
    required this.title,
    required this.message,
    required this.accentColor,
    required this.iconData,
    required this.duration,
    required this.holder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ClipRRect(
        borderRadius: AppDimensions.roundedLg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary.withOpacity(0.94),
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(
                color: accentColor.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: accentColor.withOpacity(0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Row: accent bar + icon + text + close
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left accent bar
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppDimensions.radiusLg),
                            bottomLeft: Radius.circular(AppDimensions.radiusLg),
                          ),
                        ),
                      ),

                      const SizedBox(width: AppDimensions.p12),

                      // Icon halo
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withOpacity(0.28),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(iconData, color: accentColor, size: 18),
                          ),
                        ),
                      ),

                      const SizedBox(width: AppDimensions.p12),

                      // Text content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                message,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dismiss button
                      GestureDetector(
                        onTap: () => toastification.dismiss(holder),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                          child: Icon(
                            AppIcons.close,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Auto-dismiss progress bar
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: duration,
                  builder: (ctx, val, _) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppDimensions.radiusLg),
                        bottomRight: Radius.circular(AppDimensions.radiusLg),
                      ),
                      child: LinearProgressIndicator(
                        value: val,
                        minHeight: 2.5,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accentColor.withOpacity(0.7),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
