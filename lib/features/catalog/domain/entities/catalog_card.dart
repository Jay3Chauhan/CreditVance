/// Card Tab Details (earn-categories, lounge-access, etc.)
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

/// Catalog Credit Card domain entity.
class CatalogCard {
  final int id;
  final String name;
  final String slug;
  final String bankName;
  final String bankSlug;
  final String network; // Visa, Mastercard, Amex, RuPay, Diners Club
  final String cardType; // Premium, Super-Premium, Entry, Cashback, Travel
  final double annualFee;
  final double joiningFee;
  final double? feeWaiverSpend;
  final String rewardType; // Cashback, Reward Points, Miles
  final double baseReturnRate; // e.g. 3.3 for 3.3% return
  final String? imageUrl;
  final String? bankLogoUrl;
  final bool isPopular;
  final double rating;
  final List<String> keyPerks;
  final Map<String, CardTabDetail> tabs;

  const CatalogCard({
    required this.id,
    required this.name,
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
    this.imageUrl,
    this.bankLogoUrl,
    this.isPopular = false,
    this.rating = 4.5,
    this.keyPerks = const [],
    this.tabs = const {},
  });

  bool get isLifetimeFree => annualFee == 0;
}
