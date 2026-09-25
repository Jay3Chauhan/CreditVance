import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/shimmer_card_skeleton.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../providers/advisor_provider.dart';
import '../widgets/recommendation_card.dart';

/// Smart Advisor Home Screen: "Which card should I use right now?"
/// Strictly Zero setState: Uses Provider & Consumers.
class AdvisorScreen extends StatelessWidget {
  const AdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quickAmounts = [500.0, 2000.0, 5000.0, 10000.0, 25000.0, 50000.0];

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Advisor', style: AppTypography.headlineLarge),
            Text(
              'Maximized Returns at Checkout',
              style: AppTypography.labelSmall.copyWith(color: AppColors.goldLight),
            ),
          ],
        ),
      ),
      body: Consumer<AdvisorProvider>(
        builder: (context, advisor, _) {
          return SingleChildScrollView(
            padding: AppDimensions.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Picker Section
                Text('Where are you spending?', style: AppTypography.titleSmall),
                const SizedBox(height: AppDimensions.p12),

                Consumer<CatalogProvider>(
                  builder: (context, catalog, _) {
                    final categories = catalog.categories;
                    return SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          final cat = categories[idx];
                          final isSelected =
                              advisor.selectedCategory.toLowerCase() == cat.slug.toLowerCase();

                          IconData iconData;
                          switch (cat.slug.toLowerCase()) {
                            case 'dining':
                              iconData = AppIcons.dining;
                              break;
                            case 'education':
                              iconData = AppIcons.education;
                              break;
                            case 'flights':
                              iconData = AppIcons.flights;
                              break;
                            case 'fuel':
                              iconData = AppIcons.fuel;
                              break;
                            case 'gift cards':
                              iconData = AppIcons.milestone;
                              break;
                            case 'grocery':
                              iconData = AppIcons.grocery;
                              break;
                            case 'insurance':
                              iconData = AppIcons.shieldCheck;
                              break;
                            case 'international':
                              iconData = AppIcons.international;
                              break;
                            case 'online shopping':
                            case 'shopping':
                              iconData = AppIcons.shopping;
                              break;
                            case 'rent':
                              iconData = AppIcons.rent;
                              break;
                            case 'travel':
                              iconData = AppIcons.travel;
                              break;
                            case 'upi':
                              iconData = AppIcons.navWallet;
                              break;
                            case 'utilities':
                              iconData = AppIcons.utilities;
                              break;
                            default:
                              iconData = AppIcons.navAdvisor;
                          }

                          return GestureDetector(
                            onTap: () {
                              HapticsHelper.selection();
                              advisor.setCategory(cat.slug);
                            },
                            child: AnimatedContainer(
                              duration: AppDimensions.fastAnim,
                              width: 80,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.gold.withOpacity(0.18)
                                    : AppColors.surfaceSecondary,
                                borderRadius: AppDimensions.roundedMd,
                                border: Border.all(
                                  color: isSelected ? AppColors.gold : AppColors.borderSubtle,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    iconData,
                                    size: 24,
                                    color: isSelected ? AppColors.gold : AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat.name,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSelected ? AppColors.goldLight : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.p24),

                // Spend Amount Section with Slider & Quick Chips
                LuxuryGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transaction Spend', style: AppTypography.titleSmall),
                          Text(
                            CurrencyFormatter.format(advisor.spendAmount),
                            style: AppTypography.currencyMedium.copyWith(color: AppColors.goldLight),
                          ),
                        ],
                      ),
                      Slider(
                        value: advisor.spendAmount,
                        min: 100,
                        max: 100000,
                        divisions: 100,
                        activeColor: AppColors.gold,
                        inactiveColor: AppColors.surfaceElevated,
                        onChanged: (val) {
                          advisor.setSpendAmount(val);
                        },
                      ),
                      const SizedBox(height: AppDimensions.p8),

                      // Quick Amount Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: quickAmounts.map((amt) {
                            final isCurrent = (advisor.spendAmount - amt).abs() < 50;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                selected: isCurrent,
                                label: Text(CurrencyFormatter.format(amt)),
                                labelStyle: AppTypography.labelSmall.copyWith(
                                  color: isCurrent ? AppColors.canvasDark : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: AppColors.surfaceElevated,
                                selectedColor: AppColors.gold,
                                side: BorderSide(
                                  color: isCurrent ? AppColors.gold : AppColors.borderSubtle,
                                ),
                                onSelected: (_) {
                                  HapticsHelper.selection();
                                  advisor.setSpendAmount(amt);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.p16),

                // International Forex Toggle
                LuxuryGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(AppIcons.international, color: AppColors.sapphire, size: 22),
                      const SizedBox(width: AppDimensions.p12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('International Currency (Forex)', style: AppTypography.titleSmall),
                            Text(
                              'Optimizes for lowest forex markup + reward delta',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: advisor.isInternational,
                        activeColor: AppColors.gold,
                        onChanged: (val) {
                          HapticsHelper.selection();
                          advisor.setInternational(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.p24),

                // Recommendation Outcome
                Builder(
                  builder: (context) {
                    if (advisor.state.isLoading) {
                      return const ShimmerCardSkeleton(height: 220);
                    }

                    if (advisor.state.isError && advisor.recommendation == null) {
                      return ErrorStateView(
                        message: advisor.errorMessage ?? 'Failed to compute recommendation',
                        onRetry: () => advisor.fetchRecommendation(),
                      );
                    }

                    if (advisor.recommendation != null) {
                      return RecommendationCard(recommendation: advisor.recommendation!);
                    }

                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: AppDimensions.p32),
              ],
            ),
          );
        },
      ),
    );
  }
}
