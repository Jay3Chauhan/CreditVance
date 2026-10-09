import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Payment network mark (Visa, Mastercard, Amex, RuPay, Diners).
/// Designed to sit on the dark card surface.
class NetworkLogoWidget extends StatelessWidget {
  final String network;
  final double height;
  final double? width;
  final bool useSvg;

  const NetworkLogoWidget({
    super.key,
    required this.network,
    this.height = 20.0,
    this.width,
    this.useSvg = false,
  });

  @override
  Widget build(BuildContext context) {
    final png = AppAssets.getNetworkLogoPng(network);
    final svg = AppAssets.getNetworkLogoSvg(network);

    if (useSvg && svg != null) {
      return SvgPicture.asset(svg, height: height, width: width, placeholderBuilder: (_) => _fallback());
    }
    if (png != null) {
      return Image.asset(
        png,
        height: height,
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final label = network.split(RegExp(r'\s+')).first.toUpperCase();
    return Text(
      label,
      style: AppTypography.numeric(height * 0.55, weight: FontWeight.w800, color: AppColors.cardText)
          .copyWith(fontStyle: FontStyle.italic, letterSpacing: 0.5),
    );
  }
}
