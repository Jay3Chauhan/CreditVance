import '../../domain/entities/catalog_card.dart';

/// DTO for [CatalogCard] (FastAPI schema + local fallbacks).
class CatalogCardModel extends CatalogCard {
  const CatalogCardModel({
    required super.id,
    required super.name,
    super.displayName,
    required super.slug,
    required super.bankName,
    required super.bankSlug,
    required super.network,
    required super.cardType,
    required super.annualFee,
    required super.joiningFee,
    super.feeWaiverSpend,
    required super.rewardType,
    required super.baseReturnRate,
    super.maxReturnRate,
    super.returnRangeLabel,
    super.forexMarkup,
    super.imageUrl,
    super.bankLogoUrl,
    super.isPopular,
    super.isCurrentlyIssuing,
    super.rating,
    super.overview,
    super.keyPerks,
    super.loungeTypes,
    super.benefitTypes,
    super.availableTabs,
    super.tabs,
  });

  static String? _nonEmpty(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static List<String> _strings(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : const [];

  factory CatalogCardModel.fromJson(Map<String, dynamic> json) {
    final bank = json['bank'] is Map<String, dynamic> ? json['bank'] as Map<String, dynamic> : null;

    final name = _nonEmpty(json['title']) ??
        _nonEmpty(json['name']) ??
        _nonEmpty(json['display_name']) ??
        'Credit Card';

    final renewalFee = (json['renewal_fee'] as num?)?.toDouble() ?? (json['annual_fee'] as num?)?.toDouble() ?? 0.0;
    final joiningFee = (json['joining_fee'] as num?)?.toDouble() ?? 0.0;
    final baseReturn =
        (json['return_min_percent'] as num?)?.toDouble() ?? (json['base_return_rate'] as num?)?.toDouble() ?? 1.0;
    final maxReturn = (json['return_max_percent'] as num?)?.toDouble();

    final loungeTypes = _strings(json['lounge_types']);
    final benefitTypes = _strings(json['benefit_types']);
    final overview = _nonEmpty(json['overview_text']);

    final perks = <String>[];
    final explicitPerks = _strings(json['key_perks']);
    if (explicitPerks.isNotEmpty) {
      perks.addAll(explicitPerks);
    } else {
      for (final b in benefitTypes) {
        final label = benefitLabel(b);
        if (label != null && !perks.contains(label)) perks.add(label);
      }
      for (final l in loungeTypes) {
        final label = loungeLabel(l);
        if (label != null && !perks.contains(label)) perks.add(label);
      }
    }

    final parsedTabs = <String, CardTabDetail>{};
    final rawTabs = json['tabs'];
    if (rawTabs is Map<String, dynamic>) {
      rawTabs.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedTabs[key] = CardTabDetail(
            title: value['title'] as String? ?? key,
            description: value['description'] as String? ?? '',
            bulletPoints: _strings(value['bullet_points']),
          );
        }
      });
    }

    return CatalogCardModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: name,
      displayName: _nonEmpty(json['display_name']),
      slug: json['slug'] as String? ?? '',
      bankName: _nonEmpty(json['bank_name']) ?? _nonEmpty(bank?['name']) ?? 'Bank',
      bankSlug: _nonEmpty(json['bank_slug']) ?? _nonEmpty(bank?['slug']) ?? '',
      network: formatNetwork(json['network_type'] as String? ?? json['network'] as String? ?? ''),
      cardType: _nonEmpty(json['card_type']) ??
          (renewalFee >= 10000
              ? 'Super Premium'
              : renewalFee >= 2500
                  ? 'Premium'
                  : renewalFee > 0
                      ? 'Everyday'
                      : 'Lifetime Free'),
      annualFee: renewalFee,
      joiningFee: joiningFee,
      feeWaiverSpend: (json['fee_waiver_spend'] as num?)?.toDouble(),
      rewardType: _nonEmpty(json['reward_type']) ?? 'Reward Points',
      baseReturnRate: baseReturn,
      maxReturnRate: maxReturn,
      returnRangeLabel: _nonEmpty(json['return_percentage_raw']),
      forexMarkup: (json['forex_markup_percent'] as num?)?.toDouble(),
      imageUrl: _nonEmpty(json['card_image_url']) ?? _nonEmpty(json['web_logo_url']) ?? _nonEmpty(json['image_url']),
      bankLogoUrl: _nonEmpty(json['bank_logo_url']) ?? _nonEmpty(bank?['logo_url']),
      isPopular: json['is_popular'] as bool? ?? false,
      isCurrentlyIssuing: json['is_currently_issuing'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      overview: overview,
      keyPerks: perks,
      loungeTypes: loungeTypes,
      benefitTypes: benefitTypes,
      availableTabs: _strings(json['available_tabs']),
      tabs: parsedTabs,
    );
  }

  static String formatNetwork(String network) {
    final upper = network.toUpperCase();
    if (upper.contains('VISA')) return 'Visa';
    if (upper.contains('MASTER')) return 'Mastercard';
    if (upper.contains('AMEX') || upper.contains('AMERICAN')) return 'American Express';
    if (upper.contains('RUPAY')) return 'RuPay';
    if (upper.contains('DINER')) return 'Diners Club';
    if (network.trim().isEmpty) return 'Visa';
    return network;
  }

  /// Backend network filter codes (VISA, MASTERCARD, RUPAY, AMEX).
  static String networkCode(String network) {
    final upper = network.toUpperCase();
    if (upper.contains('AMEX') || upper.contains('AMERICAN')) return 'AMEX';
    if (upper.contains('MASTER')) return 'MASTERCARD';
    if (upper.contains('RUPAY')) return 'RUPAY';
    if (upper.contains('DINER')) return 'DINERS';
    return 'VISA';
  }

  static String? benefitLabel(String benefit) {
    switch (benefit) {
      case 'DINING_ORDER_IN':
        return 'Dining & food delivery offers';
      case 'TRAVEL':
        return 'Accelerated travel rewards';
      case 'MEMBERSHIP':
        return 'Complimentary memberships';
      case 'CONCIERGE':
        return '24/7 concierge';
      case 'GOLF':
        return 'Complimentary golf';
      case 'MOVIES_AND_EVENTS':
        return 'Movie & event offers';
      case 'SHOPPING':
        return 'Shopping rewards';
      case 'INSURANCE':
        return 'Travel & accident insurance';
      case 'VOUCHERS':
        return 'Welcome & milestone vouchers';
      case 'FUEL':
        return 'Fuel surcharge waiver';
      case 'CASHBACK':
        return 'Cashback on spends';
      default:
        return null;
    }
  }

  static String? loungeLabel(String lounge) {
    switch (lounge) {
      case 'DOMESTIC_LOUNGE':
        return 'Domestic airport lounges';
      case 'INTERNATIONAL_LOUNGE':
        return 'International airport lounges';
      case 'ADD_ON_CARD_DOMESTIC_LOUNGE':
        return 'Domestic lounges for add-on cards';
      case 'ADD_ON_CARD_INTERNATIONAL_LOUNGE':
        return 'International lounges for add-on cards';
      case 'ADD_ON_CARD_LOUNGE':
        return 'Lounge access on add-on cards';
      case 'RAILWAY_LOUNGE':
        return 'Railway lounges';
      default:
        return null;
    }
  }

  factory CatalogCardModel.fromEntity(CatalogCard c) => CatalogCardModel(
        id: c.id,
        name: c.name,
        displayName: c.displayName,
        slug: c.slug,
        bankName: c.bankName,
        bankSlug: c.bankSlug,
        network: c.network,
        cardType: c.cardType,
        annualFee: c.annualFee,
        joiningFee: c.joiningFee,
        feeWaiverSpend: c.feeWaiverSpend,
        rewardType: c.rewardType,
        baseReturnRate: c.baseReturnRate,
        maxReturnRate: c.maxReturnRate,
        returnRangeLabel: c.returnRangeLabel,
        forexMarkup: c.forexMarkup,
        imageUrl: c.imageUrl,
        bankLogoUrl: c.bankLogoUrl,
        isPopular: c.isPopular,
        isCurrentlyIssuing: c.isCurrentlyIssuing,
        rating: c.rating,
        overview: c.overview,
        keyPerks: c.keyPerks,
        loungeTypes: c.loungeTypes,
        benefitTypes: c.benefitTypes,
        availableTabs: c.availableTabs,
        tabs: c.tabs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': name,
        'display_name': displayName,
        'slug': slug,
        'bank_name': bankName,
        'bank_slug': bankSlug,
        'network_type': network,
        'card_type': cardType,
        'renewal_fee': annualFee,
        'joining_fee': joiningFee,
        'fee_waiver_spend': feeWaiverSpend,
        'reward_type': rewardType,
        'return_min_percent': baseReturnRate,
        'return_max_percent': maxReturnRate,
        'return_percentage_raw': returnRangeLabel,
        'forex_markup_percent': forexMarkup,
        'card_image_url': imageUrl,
        'bank_logo_url': bankLogoUrl,
        'is_popular': isPopular,
        'is_currently_issuing': isCurrentlyIssuing,
        'rating': rating,
        'overview_text': overview,
        'key_perks': keyPerks,
        'lounge_types': loungeTypes,
        'benefit_types': benefitTypes,
        'available_tabs': availableTabs,
      };
}
