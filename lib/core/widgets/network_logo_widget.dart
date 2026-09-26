import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// Reusable Payment Network Logo Widget (Visa, Mastercard, Amex, RuPay, Diners Club, Discover).
/// Uses high-resolution transparent PNG by default for pristine rendering on dark obsidian surfaces
/// and zero SVG Inkscape parsing warnings, with SVG support available via [useSvg].
class NetworkLogoWidget extends StatelessWidget {
  final String network;
  final double height;
  final double? width;
  final BoxFit fit;
  final bool isLuxuryPill;
  final bool useSvg;

  const NetworkLogoWidget({
    super.key,
    required this.network,
    this.height = 20.0,
    this.width,
    this.fit = BoxFit.contain,
    this.isLuxuryPill = false,
    this.useSvg = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetPng = AppAssets.getNetworkLogoPng(network);
    final assetSvg = AppAssets.getNetworkLogoSvg(network);

    Widget logoContent;

    if (useSvg && assetSvg != null) {
      logoContent = SvgPicture.asset(
        assetSvg,
        height: height,
        width: width,
        fit: fit,
        placeholderBuilder: (_) => _buildFallbackText(),
      );
    } else if (assetPng != null) {
      logoContent = Image.asset(
        assetPng,
        height: height,
        width: width,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _buildFallbackText(),
      );
    } else {
      logoContent = _buildFallbackText();
    }

    if (isLuxuryPill) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
          border: Border.all(color: AppColors.borderSubtle, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: logoContent,
      );
    }

    return logoContent;
  }

  Widget _buildFallbackText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: Text(
        network.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          fontSize: 9.5,
        ),
      ),
    );
  }
}
