import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/shimmer_card_skeleton.dart';
import '../../domain/entities/user_card.dart';
import '../providers/wallet_provider.dart';
import '../widgets/visual_credit_card.dart';
import 'add_card_screen.dart';

/// Wallet & Zero-Knowledge Vault Screen.
/// Strictly Zero setState: Uses Provider Consumers and ValueNotifier.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zero-Knowledge Vault', style: AppTypography.headlineLarge),
            Text(
              'Hardware Encrypted • Device Only',
              style: AppTypography.labelSmall.copyWith(color: AppColors.emeraldLight),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add, color: AppColors.gold, size: 26),
            tooltip: 'Add New Card',
            onPressed: () {
              HapticsHelper.light();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddCardScreen()),
              );
            },
          ),
          const SizedBox(width: AppDimensions.p8),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, _) {
          final state = walletProvider.state;

          if (state.isLoading) {
            return const Padding(
              padding: AppDimensions.screenPadding,
              child: Column(
                children: [
                  ShimmerCardSkeleton(height: 210),
                  SizedBox(height: AppDimensions.p24),
                  ShimmerListSkeleton(count: 3),
                ],
              ),
            );
          }

          if (state.isError && walletProvider.cards.isEmpty) {
            return ErrorStateView(
              message: walletProvider.errorMessage ?? 'Failed to load wallet cards',
              onRetry: () => walletProvider.loadCards(),
            );
          }

          if (walletProvider.cards.isEmpty) {
            return EmptyStateView(
              title: 'Your Vault is Empty',
              message:
                  'Store your credit card numbers securely inside your phone\'s hardware KeyStore for instant one-tap copy at checkout.',
              icon: AppIcons.navWallet,
              buttonLabel: 'Add Your First Card',
              onButtonPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddCardScreen()),
                );
              },
            );
          }

          final cards = walletProvider.cards;
          final pageController = PageController(
            viewportFraction: 0.88,
            initialPage: walletProvider.focusedIndex,
          );

          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.surfacePrimary,
            onRefresh: () => walletProvider.loadCards(isRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.p8),

                  // Interactive 3D Card Carousel
                  SizedBox(
                    height: 228,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: cards.length,
                      onPageChanged: (index) {
                        HapticsHelper.selection();
                        walletProvider.setFocusedIndex(index);
                      },
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        final isUnmasked = walletProvider.isCardUnmasked(card.id);
                        final unmaskedData = walletProvider.getUnmaskedData(card.id);

                        return AnimatedBuilder(
                          animation: pageController,
                          builder: (context, child) {
                            double scale = 1.0;
                            if (pageController.position.haveDimensions) {
                              final double page = pageController.page ?? 0.0;
                              final double diff = (page - index).abs();
                              scale = (1.0 - (diff * 0.08)).clamp(0.92, 1.0);
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: VisualCreditCard(
                                card: card,
                                scale: scale,
                                isUnmasked: isUnmasked,
                                unmaskedPan: unmaskedData?['pan'],
                                unmaskedCvv: unmaskedData?['cvv'],
                                unmaskedExpiry: unmaskedData?['expiry'],
                                onToggleReveal: () async {
                                  final success = await walletProvider.revealCardDetails(card.id);
                                  if (!success && !isUnmasked && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Biometric authentication cancelled')),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Carousel Indicator Dots
                  const SizedBox(height: AppDimensions.p12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(cards.length, (idx) {
                        final isFocused = idx == walletProvider.focusedIndex;
                        return AnimatedContainer(
                          duration: AppDimensions.fastAnim,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isFocused ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isFocused ? AppColors.gold : AppColors.surfaceElevated,
                            borderRadius: AppDimensions.roundedFull,
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.p20),

                  // Action Panel for Focused Card
                  Padding(
                    padding: AppDimensions.screenHorizontal,
                    child: Builder(
                      builder: (context) {
                        final currentCard = cards[walletProvider.focusedIndex];
                        final isUnmasked = walletProvider.isCardUnmasked(currentCard.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Action Buttons (One-Tap Copy & Reveal)
                            Row(
                              children: [
                                Expanded(
                                  child: LuxuryButton(
                                    label: 'Copy Number',
                                    icon: AppIcons.copy,
                                    onPressed: () async {
                                      final success = await walletProvider.copyCardNumber(currentCard.id);
                                      if (success && context.mounted) {
                                        HapticsHelper.medium();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(AppIcons.check, color: AppColors.canvasDark),
                                                SizedBox(width: 8),
                                                Text('Card copied! Auto-clears in 30s'),
                                              ],
                                            ),
                                            backgroundColor: AppColors.gold,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: AppDimensions.roundedMd,
                                            ),
                                          ),
                                        );
                                      } else if (!success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Biometric verification failed')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.p12),
                                Expanded(
                                  child: LuxuryButton(
                                    label: isUnmasked ? 'Lock Details' : 'Unlock Card',
                                    icon: isUnmasked ? AppIcons.lock : AppIcons.unlock,
                                    variant: LuxuryButtonVariant.secondary,
                                    onPressed: () async {
                                      await walletProvider.revealCardDetails(currentCard.id);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppDimensions.p20),

                            // Security & Card Spec Card
                            LuxuryGlassCard(
                              padding: const EdgeInsets.all(AppDimensions.p16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Security Level', style: AppTypography.bodySmall),
                                      const LuxuryBadge(
                                        label: 'Hardware KeyStore',
                                        icon: AppIcons.shieldCheck,
                                        variant: LuxuryBadgeVariant.emerald,
                                        isSmall: true,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Annual Fee', style: AppTypography.bodySmall),
                                      Text(
                                        currentCard.annualFee == 0
                                            ? 'Lifetime Free (₹0)'
                                            : CurrencyFormatter.format(currentCard.annualFee),
                                        style: AppTypography.titleSmall.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (currentCard.billingCycleDay != null) ...[
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Billing Cycle Day', style: AppTypography.bodySmall),
                                        Text(
                                          '${currentCard.billingCycleDay}th of every month',
                                          style: AppTypography.titleSmall.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Manage Card', style: AppTypography.bodySmall),
                                      TextButton.icon(
                                        onPressed: () {
                                          _showDeleteConfirmation(context, walletProvider, currentCard);
                                        },
                                        icon: const Icon(AppIcons.delete, size: 16, color: AppColors.rose),
                                        label: Text(
                                          'Remove',
                                          style: AppTypography.labelSmall.copyWith(color: AppColors.rose),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppDimensions.p32),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WalletProvider provider,
    UserCard card,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfacePrimary,
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
          title: Text('Remove ${card.nickname}?', style: AppTypography.headlineMedium),
          content: Text(
            'This card and its hardware-encrypted credentials will be permanently erased from this device.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            LuxuryButton(
              label: 'Delete',
              variant: LuxuryButtonVariant.danger,
              height: 42,
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await provider.deleteCard(card.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card removed from vault')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
