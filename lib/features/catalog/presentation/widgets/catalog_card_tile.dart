import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/network_logo_widget.dart';
import '../../domain/entities/catalog_card.dart';
import '../screens/card_detail_screen.dart';

/// Card catalog list item showing bank logo, card artwork thumbnail, core perks, fee tier, and return multiplier.
/// Staggered entrance animation via flutter_animate using [listIndex].
class CatalogCardTile extends StatelessWidget {
  final CatalogCard card;
  final int listIndex;

  const CatalogCardTile({super.key, required this.card, this.listIndex = 0});

  @override
  Widget build(BuildContext context) {
    return LuxuryGlassCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CardDetailScreen(card: card),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Bank Logo + Bank Name + Return Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (card.bankLogoUrl != null && card.bankLogoUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 22,
                        height: 22,
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
                  Text(
                    card.bankName.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              LuxuryBadge(
                label: '${CurrencyFormatter.formatPercentage(card.baseReturnRate)} Return',
                variant: card.baseReturnRate >= 4.0
                    ? LuxuryBadgeVariant.emerald
                    : LuxuryBadgeVariant.gold,
                isSmall: true,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.p12),

          // Middle Row: Card Title + Optional Mini Card Artwork Thumbnail
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.name,
                  style: AppTypography.headlineMedium.copyWith(fontSize: 17),
                ),
              ),
              if (card.imageUrl != null && card.imageUrl!.isNotEmpty) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 52,
                    height: 33,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: card.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimensions.p8),

          // Badges: Network, Fee, Popular
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppDimensions.roundedFull,
                  border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NetworkLogoWidget(network: card.network, height: 11),
                    const SizedBox(width: 5),
                    Text(
                      card.network,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              LuxuryBadge(
                label: card.isLifetimeFree
                    ? 'Lifetime Free'
                    : '${CurrencyFormatter.format(card.annualFee)} / yr',
                variant: card.isLifetimeFree
                    ? LuxuryBadgeVariant.emerald
                    : LuxuryBadgeVariant.neutral,
                isSmall: true,
              ),
              if (card.isPopular)
                const LuxuryBadge(
                  label: 'Popular',
                  icon: AppIcons.star,
                  variant: LuxuryBadgeVariant.gold,
                  isSmall: true,
                ),
            ],
          ),

          if (card.keyPerks.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.p12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(AppIcons.check, size: 14, color: AppColors.emerald),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    card.keyPerks.first,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(
      delay: Duration(milliseconds: (listIndex * 45).clamp(0, 500)),
    ).fadeIn(duration: 350.ms).slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}
