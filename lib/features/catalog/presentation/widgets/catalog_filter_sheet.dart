import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../providers/catalog_provider.dart';

/// Modal bottom sheet for filtering and sorting the 731+ cards catalog.
class CatalogFilterSheet extends StatelessWidget {
  const CatalogFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters & Sort', style: AppTypography.headlineMedium),
                      IconButton(
                        icon: const Icon(AppIcons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.p16),

                  // Sort By Section
                  Text('Sort By', style: AppTypography.titleSmall),
                  const SizedBox(height: AppDimensions.p8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip(provider, 'popular', 'Most Popular'),
                      _buildSortChip(provider, 'return', 'Highest Return Rate'),
                      _buildSortChip(provider, 'fee_asc', 'Lowest Annual Fee'),
                      _buildSortChip(provider, 'fee_desc', 'Premium Tier'),
                    ],
                  ),

                  const Divider(height: 32),

                  // Annual Fee Tier
                  Text('Annual Fee Tier', style: AppTypography.titleSmall),
                  const SizedBox(height: AppDimensions.p8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeeChip(provider, null, 'All Fees'),
                      _buildFeeChip(provider, 'free', 'Lifetime Free (₹0)'),
                      _buildFeeChip(provider, 'lt1k', '< ₹1,000 / yr'),
                      _buildFeeChip(provider, '1k5k', '₹1,000 - ₹5,000'),
                      _buildFeeChip(provider, 'gt5k', '> ₹5,000 / yr'),
                    ],
                  ),

                  const Divider(height: 32),

                  // Network Filter
                  Text('Card Network', style: AppTypography.titleSmall),
                  const SizedBox(height: AppDimensions.p8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildNetworkChip(provider, null, 'All Networks'),
                      _buildNetworkChip(provider, 'Visa', 'Visa'),
                      _buildNetworkChip(provider, 'Mastercard', 'Mastercard'),
                      _buildNetworkChip(provider, 'American Express', 'American Express'),
                      _buildNetworkChip(provider, 'RuPay', 'RuPay'),
                    ],
                  ),

                  const Divider(height: 32),

                  // Action Buttons (Reset & Apply)
                  Row(
                    children: [
                      Expanded(
                        child: LuxuryButton(
                          label: 'Reset All',
                          variant: LuxuryButtonVariant.secondary,
                          onPressed: () {
                            provider.clearFilters();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.p12),
                      Expanded(
                        child: LuxuryButton(
                          label: 'Apply Filters',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortChip(CatalogProvider provider, String sortKey, String label) {
    final isSelected = provider.sortBy == sortKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? AppColors.canvasDark : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.gold,
      side: BorderSide(color: isSelected ? AppColors.gold : AppColors.borderSubtle),
      onSelected: (_) {
        HapticsHelper.selection();
        provider.setSortBy(sortKey);
      },
    );
  }

  Widget _buildFeeChip(CatalogProvider provider, String? feeKey, String label) {
    final isSelected = provider.selectedFeeType == feeKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? AppColors.canvasDark : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.gold,
      side: BorderSide(color: isSelected ? AppColors.gold : AppColors.borderSubtle),
      onSelected: (_) {
        HapticsHelper.selection();
        provider.setFeeFilter(feeKey);
      },
    );
  }

  Widget _buildNetworkChip(CatalogProvider provider, String? networkKey, String label) {
    final isSelected = provider.selectedNetwork == networkKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? AppColors.canvasDark : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.gold,
      side: BorderSide(color: isSelected ? AppColors.gold : AppColors.borderSubtle),
      onSelected: (_) {
        HapticsHelper.selection();
        provider.setNetworkFilter(networkKey);
      },
    );
  }
}
