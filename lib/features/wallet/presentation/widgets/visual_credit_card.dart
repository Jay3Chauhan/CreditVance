import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/card_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/network_logo_widget.dart';
import '../../domain/entities/user_card.dart';

/// 3D Realistic Luxury Credit Card component.
/// Featuring card image rendering, brushed obsidian finish, gold trim, EMV chip, and biometric unmasking.
class VisualCreditCard extends StatelessWidget {
  final UserCard card;
  final bool isUnmasked;
  final String? unmaskedPan;
  final String? unmaskedCvv;
  final String? unmaskedExpiry;
  final VoidCallback? onCopyPressed;
  final VoidCallback? onToggleReveal;
  final double scale;

  const VisualCreditCard({
    super.key,
    required this.card,
    this.isUnmasked = false,
    this.unmaskedPan,
    this.unmaskedCvv,
    this.unmaskedExpiry,
    this.onCopyPressed,
    this.onToggleReveal,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Choose fallback gradient and accent based on bank / tier
    LinearGradient cardGradient = AppColors.obsidianGradient;
    Color accentColor = AppColors.gold;

    final lowerName = card.cardName.toLowerCase();
    if (lowerName.contains('cashback')) {
      cardGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F2B22), Color(0xFF081813), Color(0xFF040A08)],
      );
      accentColor = AppColors.emerald;
    } else if (lowerName.contains('atlas') || lowerName.contains('travel') || lowerName.contains('sapphire')) {
      cardGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF132247), Color(0xFF0C1429), Color(0xFF060A14)],
      );
      accentColor = AppColors.sapphireLight;
    } else if (lowerName.contains('infinia') || lowerName.contains('magnus') || lowerName.contains('centurion')) {
      cardGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF261D10), Color(0xFF151108), Color(0xFF080603)],
      );
      accentColor = AppColors.gold;
    }

    final displayPan = isUnmasked && unmaskedPan != null && unmaskedPan!.isNotEmpty
        ? CardFormatter.formatFullPan(unmaskedPan!)
        : CardFormatter.maskCardNumber(card.last4Digits);

    final displayExp = isUnmasked && unmaskedExpiry != null && unmaskedExpiry!.isNotEmpty
        ? unmaskedExpiry!
        : '••/••';

    final displayCvv = isUnmasked && unmaskedCvv != null && unmaskedCvv!.isNotEmpty
        ? unmaskedCvv!
        : '•••';

    final hasImage = card.imageUrl != null && card.imageUrl!.isNotEmpty;

    return Transform.scale(
      scale: scale,
      child: AspectRatio(
        aspectRatio: AppDimensions.cardAspectRatio,
        child: Container(
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(
              color: isUnmasked ? accentColor.withOpacity(0.8) : AppColors.borderSubtle,
              width: isUnmasked ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnmasked ? accentColor.withOpacity(0.25) : Colors.black.withOpacity(0.45),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Card Art (if available)
              if (hasImage)
                ClipRRect(
                  borderRadius: AppDimensions.roundedLg,
                  child: CachedNetworkImage(
                    imageUrl: card.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: cardGradient,
                        borderRadius: AppDimensions.roundedLg,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: cardGradient,
                        borderRadius: AppDimensions.roundedLg,
                      ),
                    ),
                  ),
                ),

              // 2. High-contrast luxury scrim overlay
              ClipRRect(
                borderRadius: AppDimensions.roundedLg,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: hasImage
                          ? [
                              Colors.black.withOpacity(0.45),
                              Colors.black.withOpacity(0.75),
                            ]
                          : [
                              Colors.white.withOpacity(0.04),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),

              // 3. Metallic specular sheen line
              if (!hasImage)
                Positioned(
                  top: -50,
                  right: -30,
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Container(
                      width: 140,
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.07),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Card Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Bank Logo/Name & Reveal Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (card.bankLogoUrl != null && card.bankLogoUrl!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    color: Colors.black26,
                                    padding: const EdgeInsets.all(2),
                                    child: CachedNetworkImage(
                                      imageUrl: card.bankLogoUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      card.bankName.toUpperCase(),
                                      style: AppTypography.labelSmall.copyWith(
                                        color: accentColor,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      card.nickname,
                                      style: AppTypography.titleSmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.contactless,
                              size: 22,
                              color: AppColors.textSecondary,
                            ),
                            if (card.hasVaultDetails) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  HapticsHelper.light();
                                  onToggleReveal?.call();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isUnmasked
                                        ? accentColor.withOpacity(0.2)
                                        : AppColors.surfaceElevated.withOpacity(0.8),
                                    borderRadius: AppDimensions.roundedFull,
                                    border: Border.all(
                                      color: isUnmasked ? accentColor : AppColors.borderSubtle,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUnmasked ? AppIcons.eyeSlash : AppIcons.eye,
                                        size: 12,
                                        color: isUnmasked ? accentColor : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isUnmasked ? 'Hide' : 'Reveal',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: isUnmasked ? accentColor : AppColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    // Middle Row: EMV Chip & Formatted PAN
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // EMV Metallic Chip
                        Container(
                          width: 36,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5C07B), Color(0xFF997A3E)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26, width: 0.8),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Number with copy support
                        Expanded(
                          child: GestureDetector(
                            onTap: onCopyPressed,
                            child: Text(
                              displayPan,
                              style: AppTypography.cardNumber.copyWith(
                                fontSize: isUnmasked ? 14 : 16,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: Holder Name, Expiry, CVV & Network
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cardholder Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CARDHOLDER',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 8.5,
                                  color: AppColors.textTertiary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                card.cardName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Expiry & CVV
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'EXPIRES',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8.5,
                                    color: AppColors.textTertiary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  displayExp,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'CVV',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8.5,
                                    color: AppColors.textTertiary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  displayCvv,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isUnmasked ? accentColor : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),

                        // Authentic Payment Network Provider Logo & Label
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NetworkLogoWidget(
                                  network: card.network,
                                  height: 15,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    card.network,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 9.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
