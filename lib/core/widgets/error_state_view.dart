import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_typography.dart';
import 'luxury_button.dart';

/// Centralized Error Display widget with actionable retry button.
class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateView({
    super.key,
    this.title = 'Unable to Load Data',
    required this.message,
    this.onRetry,
    this.icon = AppIcons.alertCircle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(icon, size: 36, color: AppColors.error),
            )
                .animate()
                .shake(hz: 3, rotation: 0.02, duration: 600.ms)
                .then()
                .fadeIn(),
            const SizedBox(height: AppDimensions.p16),
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
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.p24),
              LuxuryButton(
                label: 'Retry Connection',
                icon: AppIcons.refresh,
                variant: LuxuryButtonVariant.outline,
                onPressed: onRetry,
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
