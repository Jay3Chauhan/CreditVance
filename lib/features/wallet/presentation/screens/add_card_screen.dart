import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/card_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/luxury_text_field.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../domain/entities/user_card.dart';
import '../providers/wallet_provider.dart';
import '../widgets/visual_credit_card.dart';

/// Screen for adding a credit card to the portfolio and secure hardware vault.
/// Supports both pre-selected card journeys and open catalog browsing.
/// Strictly Zero setState: Uses ValueNotifier for form and validation state.
class AddCardScreen extends StatelessWidget {
  final CatalogCard? preselectedCard;

  const AddCardScreen({super.key, this.preselectedCard});

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.read<CatalogProvider>();
    final availableCards = catalogProvider.cards;

    final initialCard = preselectedCard ??
        (availableCards.isNotEmpty ? availableCards.first : null);

    final selectedCardIdNotifier = ValueNotifier<int>(
      initialCard?.id ?? 1,
    );

    final nicknameController = TextEditingController(
      text: initialCard != null ? 'My ${initialCard.name}' : 'My Everyday Card',
    );
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final billingDayNotifier = ValueNotifier<int>(15);
    final isSavingNotifier = ValueNotifier<bool>(false);

    // Validation error notifiers (Zero setState)
    final panErrorNotifier = ValueNotifier<String?>(null);
    final expiryErrorNotifier = ValueNotifier<String?>(null);
    final cvvErrorNotifier = ValueNotifier<String?>(null);

    // Live preview notifier initialized with exact card visual assets
    final liveCardNotifier = ValueNotifier<UserCard>(
      UserCard(
        id: 0,
        cardId: initialCard?.id ?? 1,
        nickname: nicknameController.text,
        last4Digits: '••••',
        cardName: initialCard?.name ?? 'Credit Card',
        bankName: initialCard?.bankName ?? 'Bank',
        network: initialCard?.network ?? 'Visa',
        annualFee: initialCard?.annualFee ?? 0.0,
        imageUrl: initialCard?.imageUrl,
        bankLogoUrl: initialCard?.bankLogoUrl,
        hasVaultDetails: true,
      ),
    );

    CatalogCard resolveSelectedCard() {
      if (preselectedCard != null) return preselectedCard!;
      return availableCards.firstWhere(
        (c) => c.id == selectedCardIdNotifier.value,
        orElse: () => initialCard ?? availableCards.first,
      );
    }

    void updatePreview() {
      final activeCard = resolveSelectedCard();
      final cleanPan = cardNumberController.text.replaceAll(' ', '');
      final last4 = cleanPan.length >= 4 ? cleanPan.substring(cleanPan.length - 4) : '••••';

      final detectedNet = CardFormatter.detectNetwork(cleanPan);
      final networkToUse = (cleanPan.isNotEmpty && detectedNet != 'Credit Card')
          ? detectedNet
          : activeCard.network;

      liveCardNotifier.value = UserCard(
        id: 0,
        cardId: activeCard.id,
        nickname: nicknameController.text.isEmpty ? 'My Card' : nicknameController.text,
        last4Digits: last4,
        billingCycleDay: billingDayNotifier.value,
        cardName: activeCard.name,
        bankName: activeCard.bankName,
        network: networkToUse,
        annualFee: activeCard.annualFee,
        imageUrl: activeCard.imageUrl,
        bankLogoUrl: activeCard.bankLogoUrl,
        hasVaultDetails: cleanPan.isNotEmpty,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Text(
          preselectedCard != null ? 'Add ${preselectedCard!.bankName} Card' : 'Add Card to Vault',
          style: AppTypography.headlineLarge,
        ),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Interactive Card Preview (shows actual card image, bank logo, and real-time inputs)
            ValueListenableBuilder<UserCard>(
              valueListenable: liveCardNotifier,
              builder: (context, liveCard, _) {
                final pan = cardNumberController.text.replaceAll(' ', '');
                return VisualCreditCard(
                  card: liveCard,
                  isUnmasked: pan.isNotEmpty,
                  unmaskedPan: pan.isNotEmpty ? pan : null,
                  unmaskedExpiry: expiryController.text.isNotEmpty ? expiryController.text : null,
                  unmaskedCvv: cvvController.text.isNotEmpty ? cvvController.text : null,
                );
              },
            ),

            const SizedBox(height: AppDimensions.p20),

            // 2. Zero-Knowledge Hardware Enclave Banner
            Container(
              padding: const EdgeInsets.all(AppDimensions.p12),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.08),
                borderRadius: AppDimensions.roundedMd,
                border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.shieldCheck, color: AppColors.emerald, size: 20),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: Text(
                      'Zero-Knowledge Vault: Card PAN & CVV are saved directly into your device hardware Keychain. They are never sent to our servers.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.emeraldLight,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.p24),

            // 3. Card Selection Section
            if (preselectedCard != null) ...[
              // Preselected Card: Locked Luxury Summary View (NO DROPDOWN)
              Text('Selected Card Model', style: AppTypography.titleSmall),
              const SizedBox(height: AppDimensions.p8),
              LuxuryGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (preselectedCard!.bankLogoUrl != null &&
                        preselectedCard!.bankLogoUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 34,
                          height: 34,
                          color: Colors.black26,
                          padding: const EdgeInsets.all(2),
                          child: CachedNetworkImage(
                            imageUrl: preselectedCard!.bankLogoUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(AppIcons.navWallet, color: AppColors.gold, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preselectedCard!.bankName.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preselectedCard!.name,
                            style: AppTypography.headlineMedium.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        LuxuryBadge(
                          label: preselectedCard!.network,
                          variant: LuxuryBadgeVariant.sapphire,
                          isSmall: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preselectedCard!.isLifetimeFree
                              ? 'Lifetime Free'
                              : CurrencyFormatter.format(preselectedCard!.annualFee),
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Open Catalog: Model Dropdown Picker
              Text('Select Card Model', style: AppTypography.titleSmall),
              const SizedBox(height: AppDimensions.p8),
              ValueListenableBuilder<int>(
                valueListenable: selectedCardIdNotifier,
                builder: (context, selectedId, _) {
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
                        value: selectedId,
                        dropdownColor: AppColors.surfaceSecondary,
                        icon: const Icon(AppIcons.chevronDown, color: AppColors.textSecondary),
                        items: availableCards.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Row(
                              children: [
                                if (c.bankLogoUrl != null && c.bankLogoUrl!.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(
                                      imageUrl: c.bankLogoUrl!,
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    '${c.bankName} - ${c.name}',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            selectedCardIdNotifier.value = newId;
                            final card = availableCards.firstWhere((c) => c.id == newId);
                            nicknameController.text = 'My ${card.name}';
                            updatePreview();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: AppDimensions.p16),

            // 4. Card Nickname
            LuxuryTextField(
              label: 'Card Nickname',
              hint: 'e.g. Primary Swiggy or Travel Card',
              controller: nicknameController,
              prefixIcon: AppIcons.edit,
              onChanged: (_) => updatePreview(),
            ),

            const SizedBox(height: AppDimensions.p16),

            // 5. 16-Digit Card Number (PAN)
            ValueListenableBuilder<String?>(
              valueListenable: panErrorNotifier,
              builder: (context, errorText, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LuxuryTextField(
                      label: 'Card Number (PAN)',
                      hint: '4532 0000 0000 0000',
                      controller: cardNumberController,
                      prefixIcon: AppIcons.navWallet,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CardNumberInputFormatter()],
                      onChanged: (val) {
                        if (panErrorNotifier.value != null) {
                          panErrorNotifier.value = null;
                        }
                        updatePreview();
                      },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          errorText,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: AppDimensions.p16),

            // 6. Expiry & CVV Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: expiryErrorNotifier,
                    builder: (context, errorText, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LuxuryTextField(
                            label: 'Expiry Date',
                            hint: 'MM/YY',
                            controller: expiryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CardExpiryInputFormatter()],
                            onChanged: (val) {
                              if (expiryErrorNotifier.value != null) {
                                expiryErrorNotifier.value = null;
                              }
                              updatePreview();
                            },
                          ),
                          if (errorText != null) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                errorText,
                                style: AppTypography.labelSmall.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.p16),
                Expanded(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: cvvErrorNotifier,
                    builder: (context, errorText, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LuxuryTextField(
                            label: 'CVV / CVC',
                            hint: '•••',
                            controller: cvvController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              if (cvvErrorNotifier.value != null) {
                                cvvErrorNotifier.value = null;
                              }
                              updatePreview();
                            },
                          ),
                          if (errorText != null) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                errorText,
                                style: AppTypography.labelSmall.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.p16),

            // 7. Billing Cycle Day
            Text('Billing Statement Date', style: AppTypography.titleSmall),
            const SizedBox(height: AppDimensions.p8),
            ValueListenableBuilder<int>(
              valueListenable: billingDayNotifier,
              builder: (context, day, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      value: day.toDouble(),
                      min: 1,
                      max: 28,
                      divisions: 27,
                      activeColor: AppColors.gold,
                      inactiveColor: AppColors.surfaceElevated,
                      label: 'Day $day of month',
                      onChanged: (val) {
                        billingDayNotifier.value = val.round();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Billing statement generates on day $day of every month.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppDimensions.p32),

            // 8. Save Card Button
            ValueListenableBuilder<bool>(
              valueListenable: isSavingNotifier,
              builder: (context, isSaving, _) {
                return LuxuryButton(
                  label: 'Securely Save Card',
                  icon: AppIcons.lock,
                  isLoading: isSaving,
                  onPressed: () async {
                    final cleanPan = cardNumberController.text.replaceAll(' ', '');
                    final cleanExp = expiryController.text.trim();
                    final cleanCvv = cvvController.text.trim();
                    final targetCard = resolveSelectedCard();

                    // Validation 1: Card Number
                    if (cleanPan.length < 4) {
                      panErrorNotifier.value = 'Please enter at least 4 digits.';
                      HapticsHelper.error();
                      return;
                    }
                    if (cleanPan.length > 4 && cleanPan.length < 15) {
                      panErrorNotifier.value = 'Card numbers must be 15 or 16 digits.';
                      HapticsHelper.error();
                      return;
                    }
                    if (cleanPan.length >= 15 && !CardFormatter.validateCardNumber(cleanPan)) {
                      panErrorNotifier.value = 'Invalid card number checksum (Luhn check failed).';
                      HapticsHelper.error();
                      return;
                    }

                    // Validation 2: Expiry
                    if (cleanExp.isNotEmpty && !CardFormatter.validateExpiry(cleanExp)) {
                      expiryErrorNotifier.value = 'Enter a valid future MM/YY date.';
                      HapticsHelper.error();
                      return;
                    }

                    // Validation 3: CVV
                    if (cleanCvv.isNotEmpty && !CardFormatter.validateCvv(cleanCvv, network: targetCard.network)) {
                      cvvErrorNotifier.value = targetCard.network.toLowerCase().contains('amex')
                          ? 'Amex CVV must be 4 digits.'
                          : 'CVV must be 3 digits.';
                      HapticsHelper.error();
                      return;
                    }

                    isSavingNotifier.value = true;
                    final walletProvider = context.read<WalletProvider>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);

                    final last4 = cleanPan.length >= 4
                        ? cleanPan.substring(cleanPan.length - 4)
                        : cleanPan.padLeft(4, '0');

                    final success = await walletProvider.addCard(
                      cardId: targetCard.id,
                      nickname: nicknameController.text.trim().isEmpty
                          ? targetCard.name
                          : nicknameController.text.trim(),
                      last4Digits: last4,
                      billingCycleDay: billingDayNotifier.value,
                      fullCardNumber: cleanPan.isNotEmpty ? cleanPan : null,
                      cvv: cleanCvv.isNotEmpty ? cleanCvv : null,
                      expiry: cleanExp.isNotEmpty ? cleanExp : null,
                    );

                    isSavingNotifier.value = false;

                    if (success) {
                      HapticsHelper.medium();
                      nav.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('${targetCard.name} securely added to device vault!'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    }
                  },
                );
              },
            ),

            const SizedBox(height: AppDimensions.p32),
          ],
        ),
      ),
    );
  }
}
