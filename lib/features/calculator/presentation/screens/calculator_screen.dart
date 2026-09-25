import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/shimmer_card_skeleton.dart';
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
          return SingleChildScrollView(
            padding: AppDimensions.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Selector
                Text('Select Card to Simulate', style: AppTypography.titleSmall),
                const SizedBox(height: AppDimensions.p8),

                Consumer<CatalogProvider>(
                  builder: (context, catalog, _) {
                    final cards = catalog.cards;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: AppDimensions.roundedMd,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: calculator.selectedCardId,
                          dropdownColor: AppColors.surfaceSecondary,
                          icon: const Icon(AppIcons.chevronDown, color: AppColors.textSecondary),
                          items: cards.map((c) {
                            return DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(
                                '${c.bankName} - ${c.name}',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
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
                ),

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
                ),

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
              Text(label, style: AppTypography.bodySmall),
              Text(
                '${CurrencyFormatter.format(value)} / mo',
                style: AppTypography.titleSmall.copyWith(fontSize: 13, color: AppColors.goldLight),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: max,
            divisions: (max / 1000).round(),
            activeColor: AppColors.gold,
            inactiveColor: AppColors.surfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
