import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/spend_analytics.dart';
import 'category_visuals.dart';
import 'insights_section.dart';

/// Ranked list of merchants by net spend.
class TopMerchantsCard extends StatelessWidget {
  final List<MerchantSpend> merchants;
  final int index;

  const TopMerchantsCard({super.key, required this.merchants, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return InsightsSection(
      title: 'Top merchants',
      icon: AppIcons.store,
      accent: AppColors.pink,
      index: index,
      child: Column(
        children: [
          for (var i = 0; i < merchants.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.p12),
              child: Row(
                children: [
                  SizedBox(
                    width: AppDimensions.p24,
                    child: Text('${i + 1}', style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary)),
                  ),
                  CategoryIconTile(
                    icon: merchants[i].category.icon,
                    color: merchants[i].category.color,
                    size: AppDimensions.avatarSm,
                  ),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchants[i].merchantName,
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${merchants[i].count} visit${merchants[i].count == 1 ? '' : 's'} • ${merchants[i].category.label}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(CurrencyFormatter.format(merchants[i].amount), style: AppTypography.titleSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
