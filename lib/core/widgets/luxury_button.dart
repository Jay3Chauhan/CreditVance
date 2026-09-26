import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../utils/haptics_helper.dart';

enum LuxuryButtonVariant {
  primary,
  secondary,
  outline,
  danger,
}

/// Premium tactile button widget with gradient styling, press-scale micro-interaction.
/// Zero setState: uses `ValueNotifier<bool>` for press state.
class LuxuryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final LuxuryButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const LuxuryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LuxuryButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final pressedNotifier = ValueNotifier<bool>(false);

    Color backgroundColor;
    Color textColor;
    Border? border;
    Gradient? gradient;

    switch (variant) {
      case LuxuryButtonVariant.primary:
        gradient = isEnabled ? AppColors.goldGradient : null;
        backgroundColor = isEnabled ? AppColors.gold : AppColors.surfaceElevated;
        textColor = isEnabled ? AppColors.canvasDark : AppColors.textDisabled;
        break;
      case LuxuryButtonVariant.secondary:
        backgroundColor = AppColors.surfaceElevated;
        textColor = AppColors.textPrimary;
        border = Border.all(color: AppColors.borderSubtle);
        break;
      case LuxuryButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.gold;
        border = Border.all(color: AppColors.gold.withOpacity(0.5));
        break;
      case LuxuryButtonVariant.danger:
        backgroundColor = AppColors.error.withOpacity(0.15);
        textColor = AppColors.error;
        border = Border.all(color: AppColors.error.withOpacity(0.3));
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ValueListenableBuilder<bool>(
        valueListenable: pressedNotifier,
        builder: (context, isPressed, _) {
          return AnimatedScale(
            scale: isPressed && isEnabled ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTapDown: isEnabled ? (_) => pressedNotifier.value = true : null,
                onTapUp: isEnabled
                    ? (_) {
                        pressedNotifier.value = false;
                        HapticsHelper.light();
                        onPressed!();
                      }
                    : null,
                onTapCancel: isEnabled ? () => pressedNotifier.value = false : null,
                child: Ink(
                  decoration: BoxDecoration(
                    color: gradient == null ? backgroundColor : null,
                    gradient: gradient,
                    borderRadius: AppDimensions.roundedMd,
                    border: border,
                    boxShadow: variant == LuxuryButtonVariant.primary && isEnabled
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(isPressed ? 0.35 : 0.2),
                              blurRadius: isPressed ? 22 : 16,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(textColor),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, size: 18, color: textColor),
                                const SizedBox(width: AppDimensions.p8),
                              ],
                              Text(
                                label,
                                style: AppTypography.labelLarge.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
