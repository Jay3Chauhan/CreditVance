import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_toast.dart';
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
/// PageController lifecycle is owned by the private _WalletCarouselView StatefulWidget.
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
            return RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.surfacePrimary,
              onRefresh: () => walletProvider.loadCards(isRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: ErrorStateView(
                    message: walletProvider.errorMessage ?? 'Failed to load wallet cards',
                    onRetry: () => walletProvider.loadCards(),
                  ),
                ),
              ),
            );
          }

          if (walletProvider.cards.isEmpty) {
            return RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.surfacePrimary,
              onRefresh: () => walletProvider.loadCards(isRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: EmptyStateView(
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
                  ),
                ),
              ),
            );
          }

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

                  // 3D Card Carousel — PageController owned by StatefulWidget
                  _WalletCarouselView(
                    provider: walletProvider,
                    context: context,
                  ),

                  const SizedBox(height: AppDimensions.p20),

                  // Action Panel for Focused Card
                  Padding(
                    padding: AppDimensions.screenHorizontal,
                    child: Builder(
                      builder: (context) {
                        final currentCard = walletProvider.cards[walletProvider.focusedIndex];
                        final isUnmasked = walletProvider.isCardUnmasked(currentCard.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: LuxuryButton(
                                    label: 'Copy Number',
                                    icon: AppIcons.copy,
                                    onPressed: () async {
                                      final success = await walletProvider.copyCardNumber(currentCard.id);
                                      if (success && context.mounted) {
                                        AppToast.success(
                                          context,
                                          title: 'Card Copied',
                                          message: '${currentCard.nickname} copied! Auto-clears in 30s',
                                        );
                                      } else if (!success && context.mounted) {
                                        AppToast.error(
                                          context,
                                          title: 'Security Alert',
                                          message: 'Biometric verification failed',
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
                  AppToast.info(
                    context,
                    title: 'Card Removed',
                    message: 'Card permanently removed from vault',
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

/// Private StatefulWidget that owns the PageController lifecycle.
/// This is the ONLY allowed StatefulWidget in this feature — purely for controller management.
/// No setState calls inside the State body.
class _WalletCarouselView extends StatefulWidget {
  final WalletProvider provider;
  final BuildContext context;

  const _WalletCarouselView({
    required this.provider,
    required this.context,
  });

  @override
  State<_WalletCarouselView> createState() => _WalletCarouselViewState();
}

class _WalletCarouselViewState extends State<_WalletCarouselView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: widget.provider.focusedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.provider.cards;

    return Column(
      children: [
        // 3D Card Carousel with Matrix4 perspective tilt
        SizedBox(
          height: 228,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            onPageChanged: (index) {
              HapticsHelper.selection();
              widget.provider.setFocusedIndex(index);
            },
            itemBuilder: (context, index) {
              final card = cards[index];
              final isUnmasked = widget.provider.isCardUnmasked(card.id);
              final unmaskedData = widget.provider.getUnmaskedData(card.id);

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  double tilt = 0.0;

                  if (_pageController.position.haveDimensions) {
                    final double page = _pageController.page ?? 0.0;
                    final double diff = page - index;
                    scale = (1.0 - (diff.abs() * 0.09)).clamp(0.91, 1.0);
                    tilt = diff.clamp(-1.0, 1.0);
                  }

                  // Matrix4 perspective transform for 3D tilt
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.0008) // perspective depth
                    ..rotateY(tilt * 0.25)   // 3D Y-axis rotation
                    ..scale(scale, scale, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Transform(
                      transform: matrix,
                      alignment: FractionalOffset.center,
                      child: VisualCreditCard(
                        card: card,
                        scale: 1.0, // scale handled by Matrix4
                        isUnmasked: isUnmasked,
                        unmaskedPan: unmaskedData?['pan'],
                        unmaskedCvv: unmaskedData?['cvv'],
                        unmaskedExpiry: unmaskedData?['expiry'],
                        onToggleReveal: () async {
                          final success = await widget.provider.revealCardDetails(card.id);
                          if (!success && !isUnmasked && context.mounted) {
                            AppToast.warning(
                              context,
                              title: 'Authentication Cancelled',
                              message: 'Biometric verification was not completed',
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Animated Indicator Dots — spring curve
        const SizedBox(height: AppDimensions.p12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(cards.length, (idx) {
              final isFocused = idx == widget.provider.focusedIndex;
              return AnimatedContainer(
                duration: AppDimensions.mediumAnim,
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isFocused ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isFocused ? AppColors.gold : AppColors.surfaceElevated,
                  borderRadius: AppDimensions.roundedFull,
                  boxShadow: isFocused
                      ? const [
                          BoxShadow(
                            color: Color(0x66DFB76C), // AppColors.gold with 0.4 opacity
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : const [],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
