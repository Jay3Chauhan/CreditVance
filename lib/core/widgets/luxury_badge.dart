import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

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
    Color bg;
    Color border;
    Color text;

    switch (variant) {
      case LuxuryBadgeVariant.gold:
        bg = AppColors.gold.withOpacity(0.12);
        border = AppColors.gold.withOpacity(0.35);
        text = AppColors.goldLight;
        break;
      case LuxuryBadgeVariant.emerald:
        bg = AppColors.emerald.withOpacity(0.12);
        border = AppColors.emerald.withOpacity(0.35);
        text = AppColors.emeraldLight;
        break;
      case LuxuryBadgeVariant.sapphire:
        bg = AppColors.sapphire.withOpacity(0.12);
        border = AppColors.sapphire.withOpacity(0.35);
        text = AppColors.sapphireLight;
        break;
      case LuxuryBadgeVariant.neutral:
        bg = AppColors.surfaceElevated;
        border = AppColors.borderSubtle;
        text = AppColors.textSecondary;
        break;
      case LuxuryBadgeVariant.danger:
        bg = AppColors.rose.withOpacity(0.12);
        border = AppColors.rose.withOpacity(0.35);
        text = AppColors.rose;
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
