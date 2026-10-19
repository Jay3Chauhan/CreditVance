import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

/// Titled glass card used for every analytics section, with a staggered entrance.
class InsightsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accent;
  final Widget? trailing;
  final Widget child;
  final int index;

  const InsightsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.accent,
    this.trailing,
    required this.child,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iconColor = accent ?? c.accent;
    return LuxuryGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppDimensions.iconSm, color: iconColor),
              const SizedBox(width: AppDimensions.p8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleMedium ?? AppTypography.titleMedium),
                    if (subtitle != null) Text(subtitle!, style: context.text.bodySmall ?? AppTypography.bodySmall),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          child,
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: AppDimensions.mediumAnim)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Thin animated horizontal progress bar.
class SpendProgressBar extends StatelessWidget {
  final double value;
  final Color? color;

  const SpendProgressBar({super.key, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final barColor = color ?? c.accent;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: AppDimensions.slowAnim,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppDimensions.barRadius)),
        child: LinearProgressIndicator(
          value: animated,
          minHeight: AppDimensions.progressHeight,
          backgroundColor: c.surfaceHigh,
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ),
    );
  }
}

/// Small rounded icon tile used in list rows.
class CategoryIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CategoryIconTile({super.key, required this.icon, required this.color, this.size = AppDimensions.avatarMd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppDimensions.roundedSm,
      ),
      child: Icon(icon, size: AppDimensions.iconMd, color: color),
    );
  }
}
