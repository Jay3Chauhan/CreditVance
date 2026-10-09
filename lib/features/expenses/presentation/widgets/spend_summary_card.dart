import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../domain/entities/spend_analytics.dart';

/// Hero card: net spend for the period, change vs. previous period and key stats.
class SpendSummaryCard extends StatelessWidget {
  final SpendAnalytics analytics;

  const SpendSummaryCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final change = analytics.changeVsPrevious;
    final isUp = (change ?? 0) > 0;

    return LuxuryGlassCard(
      gradient: AppColors.obsidianGradient,
      border: Border.all(color: AppColors.borderGlow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET CARD SPEND • ${analytics.period.label.toUpperCase()}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.goldLight),
              ),
              if (change != null)
                LuxuryBadge(
                  label: '${isUp ? '+' : ''}${(change * 100).toStringAsFixed(0)}% vs prev',
                  icon: isUp ? AppIcons.trendUp : AppIcons.trendDown,
                  variant: isUp ? LuxuryBadgeVariant.danger : LuxuryBadgeVariant.emerald,
                  isSmall: true,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: analytics.netSpend),
            duration: AppDimensions.slowAnim,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              CurrencyFormatter.format(value),
              style: AppTypography.currencyLarge,
            ),
          ),
          const SizedBox(height: AppDimensions.p16),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Transactions', value: '${analytics.debitCount}')),
              Expanded(child: _Stat(label: 'Avg. ticket', value: CurrencyFormatter.format(analytics.averageTicket))),
              Expanded(
                child: _Stat(
                  label: 'Refunds',
                  value: CurrencyFormatter.format(analytics.refunds),
                  valueColor: AppColors.emeraldLight,
                ),
              ),
            ],
          ),
          if (analytics.feesAndCharges > 0 || analytics.internationalCount > 0) ...[
            const SizedBox(height: AppDimensions.p12),
            Wrap(
              spacing: AppDimensions.p8,
              runSpacing: AppDimensions.p8,
              children: [
                if (analytics.feesAndCharges > 0)
                  LuxuryBadge(
                    label: 'Fees & interest ${CurrencyFormatter.format(analytics.feesAndCharges)}',
                    icon: AppIcons.fees,
                    variant: LuxuryBadgeVariant.danger,
                    isSmall: true,
                  ),
                if (analytics.internationalCount > 0)
                  LuxuryBadge(
                    label: '${analytics.internationalCount} forex spend(s) not in total',
                    icon: AppIcons.international,
                    variant: LuxuryBadgeVariant.sapphire,
                    isSmall: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.mediumAnim).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _Stat({required this.label, required this.value, this.valueColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: AppDimensions.p4),
        Text(value, style: AppTypography.titleMedium.copyWith(color: valueColor)),
      ],
    );
  }
}
