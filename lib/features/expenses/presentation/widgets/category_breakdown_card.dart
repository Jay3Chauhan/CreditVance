import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/spend_analytics.dart';
import 'category_visuals.dart';
import 'insights_section.dart';

/// Stacked share bar plus ranked category list ("where did my money go").
class CategoryBreakdownCard extends StatelessWidget {
  final List<CategorySpend> categories;
  final int index;

  const CategoryBreakdownCard({super.key, required this.categories, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return InsightsSection(
      title: 'Where you spent',
      subtitle: 'Category breakdown',
      icon: AppIcons.navCalculator,
      index: index,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: AppDimensions.roundedFull,
            child: SizedBox(
              height: AppDimensions.stackedBarHeight,
              child: Row(
                children: [
                  for (final c in categories)
                    Expanded(
                      flex: (c.share * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: c.category.color),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.p16),
          for (final c in categories.take(6)) _CategoryRow(spend: c),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySpend spend;

  const _CategoryRow({required this.spend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p12),
      child: Row(
        children: [
          CategoryIconTile(icon: spend.category.icon, color: spend.category.color, size: AppDimensions.avatarSm),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(spend.category.label, style: AppTypography.titleSmall)),
                    Text(CurrencyFormatter.format(spend.amount), style: AppTypography.titleSmall),
                  ],
                ),
                const SizedBox(height: AppDimensions.p4),
                Row(
                  children: [
                    Expanded(child: SpendProgressBar(value: spend.share, color: spend.category.color)),
                    const SizedBox(width: AppDimensions.p8),
                    Text(
                      '${(spend.share * 100).toStringAsFixed(0)}% • ${spend.count}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
