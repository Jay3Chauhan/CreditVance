import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/recommendation.dart';

/// Glowing recommendation card highlighting optimal return at checkout.
class RecommendationCard extends StatelessWidget {
  final AdvisorRecommendation recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final top = recommendation.topCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Best Card to Swipe', style: AppTypography.headlineMedium),
            const LuxuryBadge(
              label: 'TOP PICK',
              icon: AppIcons.star,
              variant: LuxuryBadgeVariant.gold,
              isSmall: true,
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.p12),

        // Glowing Top Recommendation Container
        LuxuryGlassCard(
          border: Border.all(color: AppColors.gold, width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x2E2A2010), Color(0x1F141824)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank & Network Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    top.bankName.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.goldLight,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    top.network,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.p8),

              // Card Name
              Text(top.cardName, style: AppTypography.headlineLarge),

              const SizedBox(height: AppDimensions.p12),

              // Estimated Return Block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withOpacity(0.6),
                  borderRadius: AppDimensions.roundedMd,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED RETURN',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(top.estimatedValue),
                          style: AppTypography.currencyMedium.copyWith(color: AppColors.emeraldLight),
                        ),
                      ],
                    ),
                    LuxuryBadge(
                      label: '${CurrencyFormatter.formatPercentage(top.returnPercentage)} Back',
                      variant: LuxuryBadgeVariant.emerald,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.p12),

              // Explanatory Rationale
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(AppIcons.check, size: 16, color: AppColors.gold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      top.reason,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.p16),

              // Quick Copy from Vault Action
              Consumer<WalletProvider>(
                builder: (context, wallet, _) {
                  final matchingCard = wallet.cards.where((c) => c.cardId == top.cardId).firstOrNull;

                  if (matchingCard != null) {
                    return SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
                        ),
                        icon: const Icon(AppIcons.copy, size: 16),
                        label: Text('Copy ${matchingCard.nickname} (${matchingCard.last4Digits})'),
                        onPressed: () async {
                          final success = await wallet.copyCardNumber(matchingCard.id);
                          if (success && context.mounted) {
                            HapticsHelper.medium();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Card copied! Auto-clears in 30s')),
                            );
                          }
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        // Runners-Up (Alternatives)
        if (recommendation.runnersUp.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.p20),
          Text('Alternative Options', style: AppTypography.titleSmall),
          const SizedBox(height: AppDimensions.p12),
          ...recommendation.runnersUp.map(
            (alt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LuxuryGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alt.cardName,
                            style: AppTypography.titleSmall.copyWith(fontSize: 14),
                          ),
                          Text(
                            alt.bankName,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(alt.estimatedValue),
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.emeraldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.formatPercentage(alt.returnPercentage)} return',
                          style: AppTypography.labelSmall.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
