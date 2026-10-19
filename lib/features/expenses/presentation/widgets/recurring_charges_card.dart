import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
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
    final c = context.colors;
    final yearly = charges.fold<double>(0, (a, c) => a + c.annualisedCost);
    return InsightsSection(
      title: 'Subscriptions & recurring',
      subtitle: '≈ ${CurrencyFormatter.format(yearly)} per year',
      icon: AppIcons.recurring,
      accent: AppColors.indigo,
      index: index,
      child: Column(
        children: [
          for (final charge in charges)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.p12),
              child: Row(
                children: [
                  CategoryIconTile(icon: charge.category.icon, color: charge.category.color, size: AppDimensions.avatarSm),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(charge.merchantName, style: AppTypography.titleSmall.copyWith(color: c.textPrimary)),
                        Text(
                          '${charge.cadence.label} • next ~${_dateFormat.format(charge.nextExpectedAt)}'
                          '${charge.cardLast4 == null ? '' : ' • •• ${charge.cardLast4}'}',
                          style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(CurrencyFormatter.format(charge.lastAmount), style: AppTypography.titleSmall.copyWith(color: c.textPrimary)),
                      if (charge.hasPriceIncrease) ...[
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
