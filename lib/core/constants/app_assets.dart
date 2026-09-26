/// Centralized Asset paths for CardSage.
class AppAssets {
  const AppAssets._();

  // Network Logos (PNG - High Resolution 512x512 with transparent background)
  static const String logoVisa = 'assets/network-logo/visa.png';
  static const String logoMastercard = 'assets/network-logo/mastercard.png';
  static const String logoAmex = 'assets/network-logo/amex.png';
  static const String logoRupay = 'assets/network-logo/rupay.png';
  static const String logoDinersClub = 'assets/network-logo/dinersclub.png';
  static const String logoDiscover = 'assets/network-logo/discover.png';

  // Network Logos (SVG counterparts)
  static const String svgVisa = 'assets/network-logo/visa.svg';
  static const String svgMastercard = 'assets/network-logo/mastercard.svg';
  static const String svgAmex = 'assets/network-logo/amex.svg';
  static const String svgRupay = 'assets/network-logo/RuPay.svg';
  static const String svgDinersClub = 'assets/network-logo/dinersclub.svg';
  static const String svgDiscover = 'assets/network-logo/discover.svg';

  /// Resolves a network string (e.g. 'Visa Infinite', 'Mastercard World', 'RuPay / Visa', 'Amex')
  /// to its high-resolution PNG asset path, or null if unknown.
  static String? getNetworkLogoPng(String network) {
    final lower = network.toLowerCase().trim();
    if (lower.contains('visa')) {
      return logoVisa;
    } else if (lower.contains('mastercard') || lower.contains('master card')) {
      return logoMastercard;
    } else if (lower.contains('amex') || lower.contains('american express')) {
      return logoAmex;
    } else if (lower.contains('rupay')) {
      return logoRupay;
    } else if (lower.contains('diners') || lower.contains('diners club')) {
      return logoDinersClub;
    } else if (lower.contains('discover')) {
      return logoDiscover;
    }
    return null;
  }

  /// Resolves a network string to its SVG asset path, or null if unknown.
  static String? getNetworkLogoSvg(String network) {
    final lower = network.toLowerCase().trim();
    if (lower.contains('visa')) {
      return svgVisa;
    } else if (lower.contains('mastercard') || lower.contains('master card')) {
      return svgMastercard;
    } else if (lower.contains('amex') || lower.contains('american express')) {
      return svgAmex;
    } else if (lower.contains('rupay')) {
      return svgRupay;
    } else if (lower.contains('diners') || lower.contains('diners club')) {
      return svgDinersClub;
    } else if (lower.contains('discover')) {
      return svgDiscover;
    }
    return null;
  }
}
