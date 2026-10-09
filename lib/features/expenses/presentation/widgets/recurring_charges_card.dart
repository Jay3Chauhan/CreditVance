import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../domain/entities/recurring_charge.dart';
import 'category_visuals.dart';
import 'insights_section.dart';

/// Detected subscriptions / recurring charges with next expected date.
class RecurringChargesCard extends StatelessWidget {
  final List<RecurringCharge> charges;
  final int index;

  const RecurringChargesCard({super.key, required this.charges, this.index = 0});

  static final DateFormat _dateFormat = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final yearly = charges.fold<double>(0, (a, c) => a + c.annualisedCost);
    return InsightsSection(
      title: 'Subscriptions & recurring',
      subtitle: '≈ ${CurrencyFormatter.format(yearly)} per year',
      icon: AppIcons.recurring,
      accent: AppColors.indigo,
      index: index,
      child: Column(
        children: [
          for (final c in charges)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.p12),
              child: Row(
                children: [
                  CategoryIconTile(icon: c.category.icon, color: c.category.color, size: AppDimensions.avatarSm),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.merchantName, style: AppTypography.titleSmall),
                        Text(
                          '${c.cadence.label} • next ~${_dateFormat.format(c.nextExpectedAt)}'
                          '${c.cardLast4 == null ? '' : ' • •• ${c.cardLast4}'}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(CurrencyFormatter.format(c.lastAmount), style: AppTypography.titleSmall),
                      if (c.hasPriceIncrease) ...[
                        const SizedBox(height: AppDimensions.p4),
                        const LuxuryBadge(
                          label: 'Price up',
                          icon: AppIcons.trendUp,
                          variant: LuxuryBadgeVariant.danger,
                          isSmall: true,
                        ),
                      ],
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
