/// A detail section of a card (earn rates, lounges, milestones...).
class CardTabDetail {
  final String title;
  final String description;
  final List<String> bulletPoints;

  const CardTabDetail({
    required this.title,
    required this.description,
    this.bulletPoints = const [],
  });
}

/// Catalog credit card.
class CatalogCard {
  final int id;
  final String name;
  final String? displayName;
  final String slug;
  final String bankName;
  final String bankSlug;
  final String network;
  final String cardType;
  final double annualFee;
  final double joiningFee;
  final double? feeWaiverSpend;
  final String rewardType;
  final double baseReturnRate;
  final double? maxReturnRate;
  final String? returnRangeLabel;
  final double? forexMarkup;
  final String? imageUrl;
  final String? bankLogoUrl;
  final bool isPopular;
  final bool isCurrentlyIssuing;
  final double rating;
  final String? overview;
  final List<String> keyPerks;
  final List<String> loungeTypes;
  final List<String> benefitTypes;
  final List<String> availableTabs;
  final Map<String, CardTabDetail> tabs;

  const CatalogCard({
    required this.id,
    required this.name,
    this.displayName,
    required this.slug,
    required this.bankName,
    required this.bankSlug,
    required this.network,
    required this.cardType,
    required this.annualFee,
    required this.joiningFee,
    this.feeWaiverSpend,
    required this.rewardType,
    required this.baseReturnRate,
    this.maxReturnRate,
    this.returnRangeLabel,
    this.forexMarkup,
    this.imageUrl,
    this.bankLogoUrl,
    this.isPopular = false,
    this.isCurrentlyIssuing = true,
    this.rating = 4.5,
    this.overview,
    this.keyPerks = const [],
    this.loungeTypes = const [],
    this.benefitTypes = const [],
    this.availableTabs = const [],
    this.tabs = const {},
  });

  bool get isLifetimeFree => annualFee == 0 && joiningFee == 0;

  bool get hasLounge => loungeTypes.isNotEmpty;

  bool get hasInternationalLounge => loungeTypes.any((l) => l.contains('INTERNATIONAL'));

  /// "3% – 33%" or "3.3%".
  String get returnLabel {
    String fmt(double v) => v == v.roundToDouble() ? '${v.toInt()}%' : '${v.toStringAsFixed(1)}%';
    final max = maxReturnRate;
    if (max != null && max > baseReturnRate) return '${fmt(baseReturnRate)} – ${fmt(max)}';
    return fmt(baseReturnRate);
  }

  /// Short label e.g. "Infinia Metal".
  String get shortName {
    final d = displayName;
    if (d != null && d.trim().isNotEmpty) return d.trim();
    return name.replaceAll(RegExp(r'\s*Credit Card$', caseSensitive: false), '');
  }
}
