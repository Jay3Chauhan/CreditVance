import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.surfaceSecondary,
            onRefresh: () async {
              await Future.wait([
                advisor.refresh(),
                context.read<CatalogProvider>().refresh(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppDimensions.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Text('Where are you spending?', style: AppTypography.titleSmall)
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: AppDimensions.p12),

                  // Category Pill Chips — horizontal pill cards replacing old squares
                  Consumer<CatalogProvider>(
                    builder: (context, catalog, _) {
                      final categories = catalog.categories;
                      return SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final cat = categories[idx];
                            final isSelected =
                                advisor.selectedCategory.toLowerCase() == cat.slug.toLowerCase();

                            final iconData = _iconForCategory(cat.slug);

                            return GestureDetector(
                              onTap: () {
                                HapticsHelper.selection();
                                advisor.setCategory(cat.slug);
                              },
                              child: AnimatedContainer(
                                duration: AppDimensions.fastAnim,
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.gold.withOpacity(0.18)
                                      : AppColors.surfaceSecondary,
                                  borderRadius: AppDimensions.roundedFull,
                                  border: Border.all(
                                    color: isSelected ? AppColors.gold : AppColors.borderSubtle,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.gold.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      iconData,
                                      size: 16,
                                      color: isSelected ? AppColors.gold : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.name,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isSelected ? AppColors.goldLight : AppColors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate(
                              delay: Duration(milliseconds: idx * 35),
                            ).fadeIn(duration: 300.ms).scale(
                              begin: const Offset(0.88, 0.88),
                              end: const Offset(1.0, 1.0),
                              curve: Curves.easeOutBack,
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
                            AnimatedSwitcher(
                              duration: AppDimensions.fastAnim,
                              child: Text(
                                CurrencyFormatter.format(advisor.spendAmount),
                                key: ValueKey(advisor.spendAmount.round()),
                                style: AppTypography.currencyMedium.copyWith(
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            thumbColor: AppColors.gold,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            overlayColor: AppColors.gold.withOpacity(0.15),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                            activeTrackColor: AppColors.gold,
                            inactiveTrackColor: AppColors.surfaceElevated,
                            trackHeight: 3.0,
                          ),
                          child: Slider(
                            value: advisor.spendAmount,
                            min: 100,
                            max: 100000,
                            divisions: 100,
                            onChanged: (val) {
                              advisor.setSpendAmount(val);
                            },
                          ),
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
                  ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

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
                  ).animate(delay: 180.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

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
            ),
          );
        },
      ),
    );
  }

  static IconData _iconForCategory(String slug) {
    switch (slug.toLowerCase()) {
      case 'dining':
        return AppIcons.dining;
      case 'education':
        return AppIcons.education;
      case 'flights':
        return AppIcons.flights;
      case 'fuel':
        return AppIcons.fuel;
      case 'gift cards':
        return AppIcons.milestone;
      case 'grocery':
        return AppIcons.grocery;
      case 'insurance':
        return AppIcons.shieldCheck;
      case 'international':
        return AppIcons.international;
      case 'online shopping':
      case 'shopping':
        return AppIcons.shopping;
      case 'rent':
        return AppIcons.rent;
      case 'travel':
        return AppIcons.travel;
      case 'upi':
        return AppIcons.navWallet;
      case 'utilities':
        return AppIcons.utilities;
      default:
        return AppIcons.navAdvisor;
    }
  }
}
