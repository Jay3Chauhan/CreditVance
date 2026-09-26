import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// High-performance glassmorphic container with refined luminous borders.
/// When tappable (onTap != null): animates press glow + scale for premium tactile feedback.
/// Zero setState: uses `ValueNotifier<bool>` for press state.
class LuxuryGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Border? border;
  final Gradient? gradient;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const LuxuryGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.p16),
    this.borderRadius = AppDimensions.radiusLg,
    this.border,
    this.gradient,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return _buildCard(isPressed: false);
    }

    final pressedNotifier = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: pressedNotifier,
      builder: (context, isPressed, _) {
        return GestureDetector(
          onTapDown: (_) => pressedNotifier.value = true,
          onTapUp: (_) {
            pressedNotifier.value = false;
            onTap!();
          },
          onTapCancel: () => pressedNotifier.value = false,
          child: AnimatedScale(
            scale: isPressed ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: _buildCard(isPressed: isPressed),
          ),
        );
      },
    );
  }

  Widget _buildCard({required bool isPressed}) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceCard.withOpacity(0.85),
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: isPressed
                  ? AppColors.gold.withOpacity(0.35)
                  : AppColors.borderSubtle,
              width: isPressed ? 1.2 : 1.0,
            ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
