import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../domain/entities/calculation_result.dart';

/// Visualization of annual savings, net return, and category yield breakdown.
class ComparisonChartWidget extends StatelessWidget {
  final CalculationResult result;

  const ComparisonChartWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Net Benefit Card
        LuxuryGlassCard(
          border: Border.all(color: AppColors.emerald, width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x2E0B291A), Color(0x1F111624)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NET ANNUAL VALUE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.emeraldLight,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  LuxuryBadge(
                    label: '${CurrencyFormatter.formatPercentage(result.effectiveRoi)} Net ROI',
                    variant: LuxuryBadgeVariant.emerald,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p8),
              Text(
                CurrencyFormatter.format(result.netBenefit),
                style: AppTypography.currencyLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppDimensions.p12),

              // Fee & Gross comparison row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.p12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withOpacity(0.5),
                        borderRadius: AppDimensions.roundedMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gross Rewards', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(result.totalRewardValue),
                            style: AppTypography.titleSmall.copyWith(color: AppColors.goldLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.p8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.p12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withOpacity(0.5),
                        borderRadius: AppDimensions.roundedMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Annual Fee', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            result.annualFee == 0
                                ? 'Waived (₹0)'
                                : CurrencyFormatter.format(result.annualFee),
                            style: AppTypography.titleSmall.copyWith(
                              color: result.annualFee == 0 ? AppColors.emerald : AppColors.rose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.p20),

        // Category Breakdown
        Text('Earnings by Vertical', style: AppTypography.titleSmall),
        const SizedBox(height: AppDimensions.p12),

        ...result.breakdowns.map((cat) {
          final percentageOfTotal =
              result.totalRewardValue > 0 ? (cat.earnedRupees / result.totalRewardValue).clamp(0.0, 1.0) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LuxuryGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat.categoryName, style: AppTypography.titleSmall),
                      Text(
                        '+${CurrencyFormatter.format(cat.earnedRupees)}',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.emeraldLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spend: ${CurrencyFormatter.format(cat.spend)}',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        'Rate: ${CurrencyFormatter.formatPercentage(cat.returnPercentage)}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.goldLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar showing yield contribution
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentageOfTotal,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
