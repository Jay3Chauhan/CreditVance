import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_typography.dart';
import 'luxury_button.dart';

/// Centralized Empty State widget with customizable illustration/icon and CTA.
class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.navWallet,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.p20),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
              ),
              child: Icon(icon, size: 40, color: AppColors.gold),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.06,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: AppDimensions.p20),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: AppDimensions.p8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: AppDimensions.p24),
              LuxuryButton(
                label: buttonLabel!,
                icon: AppIcons.add,
                onPressed: onButtonPressed,
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
