import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/network_logo_widget.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/recommendation.dart';

/// Glowing recommendation card highlighting optimal return at checkout.
/// Entrance: slide-up + fade-in via flutter_animate.
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
        ).animate().fadeIn(duration: 300.ms),

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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NetworkLogoWidget(network: top.network, height: 12),
                      const SizedBox(width: 5),
                      Text(
                        top.network,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
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
                            AppToast.success(
                              context,
                              title: 'Card Copied',
                              message: 'Auto-clears from clipboard in 30s',
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
        ).animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),

        // Runners-Up (Alternatives)
        if (recommendation.runnersUp.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.p20),
          Text('Alternative Options', style: AppTypography.titleSmall)
              .animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: AppDimensions.p12),
          ...recommendation.runnersUp.asMap().entries.map(
            (entry) => Padding(
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
                            entry.value.cardName,
                            style: AppTypography.titleSmall.copyWith(fontSize: 14),
                          ),
                          Text(
                            entry.value.bankName,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(entry.value.estimatedValue),
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.emeraldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.formatPercentage(entry.value.returnPercentage)} return',
                          style: AppTypography.labelSmall.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 200 + entry.key * 60)).fadeIn().slideX(begin: 0.05, end: 0),
            ),
          ),
        ],
      ],
    );
  }
}
