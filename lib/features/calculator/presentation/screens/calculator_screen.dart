import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/shimmer_card_skeleton.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/comparison_chart_widget.dart';

/// Reward Calculator & Simulator Screen.
/// Strictly Zero setState: Uses Provider & Consumers.
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reward Calculator', style: AppTypography.headlineLarge),
            Text(
              'Simulate Annual Returns & Net ROI',
              style: AppTypography.labelSmall.copyWith(color: AppColors.goldLight),
            ),
          ],
        ),
      ),
      body: Consumer<CalculatorProvider>(
        builder: (context, calculator, _) {
          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.surfaceSecondary,
            onRefresh: () async {
              await Future.wait([
                calculator.refresh(),
                context.read<CatalogProvider>().refresh(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppDimensions.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Selector Section
                  Text('Select Card to Simulate', style: AppTypography.titleSmall)
                      .animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: AppDimensions.p8),

                  Consumer<CatalogProvider>(
                    builder: (context, catalog, _) {
                      // Deduplicate cards by id to avoid duplicate DropdownMenuItems
                      final uniqueCardsMap = <int, CatalogCard>{};
                      for (final c in catalog.cards) {
                        uniqueCardsMap[c.id] = c;
                      }
                      final cards = uniqueCardsMap.values.toList();

                      // Check if the current selectedCardId exists in the available cards list
                      final hasSelectedCard = cards.any((c) => c.id == calculator.selectedCardId);
                      final selectedValue = hasSelectedCard
                          ? calculator.selectedCardId
                          : (cards.isNotEmpty ? cards.first.id : null);

                      // If selectedCardId is missing from cards but cards are available, sync provider
                      if (!hasSelectedCard && cards.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (calculator.selectedCardId != cards.first.id) {
                            calculator.setSelectedCard(cards.first.id);
                          }
                        });
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: AppDimensions.roundedMd,
                          border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedValue,
                            hint: Text(
                              cards.isEmpty ? 'Loading cards...' : 'Select a card',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                            ),
                            dropdownColor: AppColors.surfaceSecondary,
                            icon: const Icon(AppIcons.chevronDown, color: AppColors.gold),
                            items: cards.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(
                                  '${c.bankName} - ${c.name}',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                calculator.setSelectedCard(id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: AppDimensions.p20),

                  // Monthly Spend Sliders
                  LuxuryGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Spending Allocation', style: AppTypography.titleSmall),
                        const SizedBox(height: AppDimensions.p16),

                        // Dining
                        _buildSpendSlider(
                          label: 'Dining & Food Orders',
                          value: calculator.monthlyDining,
                          max: 50000,
                          onChanged: (v) => calculator.updateSpend(dining: v),
                        ),

                        // Flights & Travel
                        _buildSpendSlider(
                          label: 'Flights & Hotel Stays',
                          value: calculator.monthlyFlights,
                          max: 60000,
                          onChanged: (v) => calculator.updateSpend(flights: v),
                        ),

                        // Grocery
                        _buildSpendSlider(
                          label: 'Groceries & Supermarkets',
                          value: calculator.monthlyGrocery,
                          max: 40000,
                          onChanged: (v) => calculator.updateSpend(grocery: v),
                        ),

                        // Online Shopping
                        _buildSpendSlider(
                          label: 'Online Shopping (Amazon, Myntra)',
                          value: calculator.monthlyShopping,
                          max: 50000,
                          onChanged: (v) => calculator.updateSpend(shopping: v),
                        ),

                        // Other
                        _buildSpendSlider(
                          label: 'General & Bill Spends',
                          value: calculator.monthlyOther,
                          max: 40000,
                          onChanged: (v) => calculator.updateSpend(other: v),
                        ),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: AppDimensions.p24),

                  // Calculation Result
                  Builder(
                    builder: (context) {
                      if (calculator.state.isLoading) {
                        return const ShimmerCardSkeleton(height: 220);
                      }

                      if (calculator.state.isError && calculator.result == null) {
                        return ErrorStateView(
                          message: calculator.errorMessage ?? 'Failed to compute rewards',
                          onRetry: () => calculator.calculate(),
                        );
                      }

                      if (calculator.result != null) {
                        return ComparisonChartWidget(result: calculator.result!);
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

  Widget _buildSpendSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.p8),
              AnimatedSwitcher(
                duration: AppDimensions.fastAnim,
                child: Text(
                  '${CurrencyFormatter.format(value)} / mo',
                  key: ValueKey(value.round()),
                  style: AppTypography.titleSmall.copyWith(fontSize: 13, color: AppColors.goldLight),
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
              value: value,
              min: 0,
              max: max,
              divisions: (max / 1000).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
