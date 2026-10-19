import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

import '../utils/context_ext.dart';

enum LuxuryBadgeVariant {
  gold,
  emerald,
  sapphire,
  neutral,
  danger,
}

/// Small pill badge for multipliers, cashback %, and categories.
class LuxuryBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final LuxuryBadgeVariant variant;
  final bool isSmall;

  const LuxuryBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = LuxuryBadgeVariant.neutral,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Color bg;
    Color border;
    Color text;

    switch (variant) {
      case LuxuryBadgeVariant.gold:
        bg = c.tint(c.accent, c.isDark ? 0.12 : 0.08);
        border = c.tint(c.accent, 0.35);
        text = c.isDark ? AppColors.goldLight : c.accent;
        break;
      case LuxuryBadgeVariant.emerald:
        bg = c.tint(c.success, c.isDark ? 0.12 : 0.08);
        border = c.tint(c.success, 0.35);
        text = c.isDark ? AppColors.emeraldLight : c.success;
        break;
      case LuxuryBadgeVariant.sapphire:
        bg = c.tint(c.info, c.isDark ? 0.12 : 0.08);
        border = c.tint(c.info, 0.35);
        text = c.isDark ? AppColors.sapphireLight : c.info;
        break;
      case LuxuryBadgeVariant.neutral:
        bg = c.surfaceAlt;
        border = c.border;
        text = c.textSecondary;
        break;
      case LuxuryBadgeVariant.danger:
        bg = c.tint(c.danger, c.isDark ? 0.12 : 0.08);
        border = c.tint(c.danger, 0.35);
        text = c.danger;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppDimensions.p8 : AppDimensions.p12,
        vertical: isSmall ? AppDimensions.p4 : AppDimensions.p4 + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimensions.roundedFull,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 12 : 14, color: text),
            const SizedBox(width: AppDimensions.p4),
          ],
          Text(
            label,
            style: (isSmall ? AppTypography.labelSmall : AppTypography.labelSmall).copyWith(
              color: text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
