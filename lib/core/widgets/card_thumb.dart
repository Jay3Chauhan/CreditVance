import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import 'network_logo_widget.dart';

/// Small card artwork: the issuer's image when available, otherwise a
/// skin-rendered placeholder that matches the wallet card.
class CardThumb extends StatelessWidget {
  final String cardName;
  final String bankName;
  final String? network;
  final String? imageUrl;
  final double width;
  final String? last4;

  const CardThumb({
    super.key,
    required this.cardName,
    required this.bankName,
    this.network,
    this.imageUrl,
    this.width = 64,
    this.last4,
  });

  @override
  Widget build(BuildContext context) {
    final skin = CardSkin.resolve(cardName: cardName, bankName: bankName);
    final height = width / AppDimensions.cardAspectRatio;
    final radius = BorderRadius.circular(width * 0.08);

    final painted = Container(
      decoration: BoxDecoration(gradient: skin.gradient, borderRadius: radius),
      padding: EdgeInsets.all(width * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width * 0.16,
            height: width * 0.12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.025),
              gradient: const LinearGradient(colors: [AppColors.cardChipLight, AppColors.cardChipDark]),
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: last4 == null
                    ? const SizedBox.shrink()
                    : Text(
                        '•• $last4',
                        style: AppTypography.cardNumber(width * 0.1, color: AppColors.cardTextMuted),
                        maxLines: 1,
                      ),
              ),
              if (network != null) NetworkLogoWidget(network: network!, height: width * 0.12),
            ],
          ),
        ],
      ),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: skin.colors.last.withValues(alpha: 0.35),
            blurRadius: width * 0.12,
            offset: Offset(0, width * 0.05),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageUrl == null || imageUrl!.isEmpty
            ? painted
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => painted,
                errorWidget: (_, _, _) => painted,
              ),
      ),
    );
  }
}
