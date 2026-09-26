import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../utils/context_ext.dart';
import 'app_button.dart';
import 'app_surface.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconHalo(icon: icon, size: 64, iconSize: 28, circle: true)
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), duration: AppDimensions.mediumAnim, curve: Curves.easeOutBack),
              const SizedBox(height: AppDimensions.p16),
              Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.p6),
              Text(message, style: context.text.bodyMedium!.copyWith(color: c.textTertiary), textAlign: TextAlign.center),
              if (actionLabel != null) ...[
                const SizedBox(height: AppDimensions.p20),
                AppButton(label: actionLabel!, onPressed: onAction, expand: false, icon: AppIcons.add),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: AppDimensions.p8),
                AppButton.ghost(label: secondaryLabel!, onPressed: onSecondary),
              ],
            ],
          ).animate().fadeIn(duration: AppDimensions.mediumAnim).slideY(begin: 0.04, end: 0),
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconHalo(icon: AppIcons.warning, color: c.danger, size: 56, iconSize: 24, circle: true),
              const SizedBox(height: AppDimensions.p14),
              Text('Couldn\'t load this', style: context.text.titleMedium),
              const SizedBox(height: AppDimensions.p4),
              Text(message, style: context.text.bodySmall, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AppDimensions.p16),
                AppButton.outline(label: AppStrings.retry, onPressed: onRetry, icon: AppIcons.refresh, compact: true, expand: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin inline banner, e.g. for offline / cached data notices.
class InlineNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? color;
  final VoidCallback? onTap;

  const InlineNotice({super.key, required this.icon, required this.message, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.info;
    return AppSurface(
      tone: SurfaceTone.accent,
      tintColor: tone,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: AppDimensions.roundedMd,
      child: Row(
        children: [
          Icon(icon, size: 16, color: tone),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: context.text.bodySmall!.copyWith(color: c.textSecondary))),
        ],
      ),
    );
  }
}
