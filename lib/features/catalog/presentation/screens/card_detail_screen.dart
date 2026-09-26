import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/network_logo_widget.dart';
import '../../../wallet/domain/entities/user_card.dart';
import '../../../wallet/presentation/screens/add_card_screen.dart';
import '../../../wallet/presentation/widgets/visual_credit_card.dart';
import '../../domain/entities/catalog_card.dart';

/// Detailed view of a Credit Card with deep tabs (Earn Multipliers, Lounges, Milestones).
/// Uses ValueNotifier for tab switching (Zero setState).
class CardDetailScreen extends StatelessWidget {
  final CatalogCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final tabsList = [
      {'key': 'earn-categories', 'label': 'Multipliers', 'icon': AppIcons.rewardPoints},
      {'key': 'lounge-access', 'label': 'Lounge Access', 'icon': AppIcons.lounge},
      {'key': 'milestones', 'label': 'Fee & Milestones', 'icon': AppIcons.milestone},
    ];

    final activeTabNotifier = ValueNotifier<int>(0);

    final mockUserCard = UserCard(
      id: 0,
      cardId: card.id,
      nickname: card.name,
      last4Digits: '8888',
      cardName: card.name,
      bankName: card.bankName,
      network: card.network,
      annualFee: card.annualFee,
      imageUrl: card.imageUrl,
      bankLogoUrl: card.bankLogoUrl,
    );

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Text(card.bankName, style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          child: LuxuryButton(
            label: 'Add to My Vault',
            icon: AppIcons.lock,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddCardScreen(preselectedCard: card),
                ),
              );
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surfaceSecondary,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Realistic Card Representation — scale+fade entrance
              VisualCreditCard(
                card: mockUserCard,
                isUnmasked: true,
                unmaskedPan: '4532 •••• •••• 8888',
                unmaskedExpiry: '12/29',
                unmaskedCvv: '777',
              ).animate().fadeIn(duration: 450.ms).scale(
                    begin: const Offset(0.93, 0.93),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: AppDimensions.p20),

              // Card Title & Quick Stats
              Text(card.name, style: AppTypography.headlineLarge)
                  .animate(delay: 120.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppDimensions.p8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  LuxuryBadge(
                    label: '${CurrencyFormatter.formatPercentage(card.baseReturnRate)} Base Return',
                    variant: LuxuryBadgeVariant.emerald,
                  ),
                  LuxuryBadge(
                    label: card.isLifetimeFree
                        ? 'Lifetime Free'
                        : 'Fee: ${CurrencyFormatter.format(card.annualFee)}',
                    variant: card.isLifetimeFree ? LuxuryBadgeVariant.emerald : LuxuryBadgeVariant.neutral,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppDimensions.roundedFull,
                      border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NetworkLogoWidget(network: card.network, height: 13),
                        const SizedBox(width: 6),
                        Text(
                          card.network,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (card.feeWaiverSpend != null)
                    LuxuryBadge(
                      label: 'Waiver at ${CurrencyFormatter.format(card.feeWaiverSpend!)}',
                      variant: LuxuryBadgeVariant.gold,
                    ),
                ],
              ).animate(delay: 200.ms).fadeIn(duration: 350.ms),

              const SizedBox(height: AppDimensions.p24),

              // Deep Feature Tabs (ValueNotifier)
              ValueListenableBuilder<int>(
                valueListenable: activeTabNotifier,
                builder: (context, activeIdx, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab Selector Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(tabsList.length, (idx) {
                            final tab = tabsList[idx];
                            final isSelected = activeIdx == idx;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSelected,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tab['icon'] as IconData,
                                      size: 14,
                                      color: isSelected ? AppColors.canvasDark : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(tab['label'] as String),
                                  ],
                                ),
                                labelStyle: AppTypography.labelSmall.copyWith(
                                  color: isSelected ? AppColors.canvasDark : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: AppColors.surfaceElevated,
                                selectedColor: AppColors.gold,
                                side: BorderSide(
                                  color: isSelected ? AppColors.gold : AppColors.borderSubtle,
                                ),
                                onSelected: (_) {
                                  HapticsHelper.selection();
                                  activeTabNotifier.value = idx;
                                },
                              ).animate(delay: Duration(milliseconds: 280 + idx * 60)).fadeIn().slideX(begin: -0.04, end: 0),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.p16),

                      // Active Tab Content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: KeyedSubtree(
                          key: ValueKey(activeIdx),
                          child: _buildActiveTabContent(card, tabsList[activeIdx]['key'] as String),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppDimensions.p32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(CatalogCard card, String tabKey) {
    final detail = card.tabs[tabKey];

    if (detail == null) {
      return LuxuryGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Features & Benefits', style: AppTypography.titleMedium),
            const SizedBox(height: AppDimensions.p12),
            ...card.keyPerks.map(
              (perk) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(AppIcons.check, size: 16, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(perk, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LuxuryGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail.title, style: AppTypography.titleMedium),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.p4),
            Text(
              detail.description,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const Divider(height: 24),
          ...detail.bulletPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(AppIcons.check, size: 16, color: AppColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
