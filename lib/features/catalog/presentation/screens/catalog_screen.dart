import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_text_field.dart';
import '../../../../core/widgets/shimmer_card_skeleton.dart';
import '../providers/catalog_provider.dart';
import '../widgets/catalog_card_tile.dart';
import '../widgets/catalog_filter_sheet.dart';

/// Cards Explorer Screen featuring 731+ cards catalog with search, bank chips, and filters.
/// Strictly Zero setState: Uses Provider Consumers.
/// TextEditingController lifecycle owned by _CatalogBody StatefulWidget.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card Explorer', style: AppTypography.headlineLarge),
            Text(
              'Compare 731+ Indian Credit Cards',
              style: AppTypography.labelSmall.copyWith(color: AppColors.goldLight),
            ),
          ],
        ),
        actions: [
          Consumer<CatalogProvider>(
            builder: (context, provider, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.filter, color: AppColors.textPrimary),
                    tooltip: 'Filter & Sort',
                    onPressed: () {
                      HapticsHelper.light();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const CatalogFilterSheet(),
                      );
                    },
                  ),
                  if (provider.hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: AppDimensions.p8),
        ],
      ),
      body: const _CatalogBody(),
    );
  }
}

/// Private StatefulWidget that owns the TextEditingController lifecycle.
/// This is the ONLY allowed StatefulWidget here — purely for controller management.
/// No setState calls in the state body — all state changes go through CatalogProvider.
class _CatalogBody extends StatefulWidget {
  const _CatalogBody();

  @override
  State<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends State<_CatalogBody> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Search Input Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LuxuryTextField(
                hint: 'Search cards, banks, or rewards...',
                controller: _searchController,
                prefixIcon: AppIcons.search,
                suffix: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(AppIcons.close, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                          duration: 350.ms,
                        )
                    : null,
                onChanged: (val) => provider.setSearchQuery(val.trim()),
              ),
            ),

            // Result count row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: AppDimensions.fastAnim,
                    child: Text(
                      provider.hasActiveFilters
                          ? '${provider.cards.length} results found'
                          : '${provider.cards.length} cards available',
                      key: ValueKey('${provider.cards.length}_${provider.hasActiveFilters}'),
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.p4),

            // Bank Horizontal Chips Selector
            if (provider.banks.isNotEmpty) ...[
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.banks.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    if (idx == 0) {
                      final isAll = provider.selectedBankSlug == null;
                      return ChoiceChip(
                        selected: isAll,
                        label: const Text('All Banks'),
                        labelStyle: AppTypography.labelSmall.copyWith(
                          color: isAll ? AppColors.canvasDark : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.surfaceSecondary,
                        selectedColor: AppColors.gold,
                        side: BorderSide(
                          color: isAll ? AppColors.gold : AppColors.borderSubtle,
                        ),
                        onSelected: (_) {
                          HapticsHelper.selection();
                          provider.setBankFilter(null);
                        },
                      );
                    }

                    final bank = provider.banks[idx - 1];
                    final isSelected = provider.selectedBankSlug == bank.slug;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(bank.name),
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: isSelected ? AppColors.canvasDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.surfaceSecondary,
                      selectedColor: AppColors.gold,
                      side: BorderSide(
                        color: isSelected ? AppColors.gold : AppColors.borderSubtle,
                      ),
                      onSelected: (_) {
                        HapticsHelper.selection();
                        provider.setBankFilter(isSelected ? null : bank.slug);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.p8),
            ],

            // Active Filter Tags Indicator
            if (provider.hasActiveFilters) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Active Filters',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        provider.clearFilters();
                      },
                      child: const LuxuryBadge(
                        label: 'Clear All',
                        variant: LuxuryBadgeVariant.danger,
                        isSmall: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Card List or State Views
            Expanded(
              child: Builder(
                builder: (context) {
                  final state = provider.state;

                  if (state.isLoading) {
                    return const Padding(
                      padding: AppDimensions.screenPadding,
                      child: ShimmerListSkeleton(count: 5),
                    );
                  }

                  if (state.isError && provider.cards.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.gold,
                      backgroundColor: AppColors.surfacePrimary,
                      onRefresh: () => provider.refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: ErrorStateView(
                            message: provider.errorMessage ?? 'Failed to load catalog',
                            onRetry: () => provider.refresh(),
                          ),
                        ),
                      ),
                    );
                  }

                  if (provider.cards.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.gold,
                      backgroundColor: AppColors.surfacePrimary,
                      onRefresh: () => provider.refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: EmptyStateView(
                            title: 'No Cards Found',
                            message: 'Try adjusting your search query or reset active filters.',
                            icon: AppIcons.search,
                            buttonLabel: 'Reset Filters',
                            onButtonPressed: () {
                              _searchController.clear();
                              provider.clearFilters();
                            },
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.gold,
                    backgroundColor: AppColors.surfacePrimary,
                    onRefresh: () => provider.refresh(),
                    child: ListView.separated(
                      padding: AppDimensions.screenPadding,
                      itemCount: provider.cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.p12),
                      itemBuilder: (context, index) {
                        final card = provider.cards[index];
                        return CatalogCardTile(card: card, listIndex: index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
