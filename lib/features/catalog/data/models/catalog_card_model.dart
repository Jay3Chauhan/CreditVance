import '../../domain/entities/catalog_card.dart';

/// DTO for CatalogCard supporting both FastAPI backend schemas and local mock fallbacks
class CatalogCardModel extends CatalogCard {
  const CatalogCardModel({
    required super.id,
    required super.name,
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
    super.imageUrl,
    super.bankLogoUrl,
    super.isPopular,
    super.rating,
    super.keyPerks,
    super.tabs,
  });

  factory CatalogCardModel.fromJson(Map<String, dynamic> json) {
    // 1. Resolve card title/name (FastAPI sends 'title' or 'display_name')
    final title = json['title'] as String?;
    final displayName = json['display_name'] as String?;
    final legacyName = json['name'] as String?;

    String rawName = 'Credit Card';
    if (title != null && title.trim().isNotEmpty) {
      rawName = title.trim();
    } else if (displayName != null && displayName.trim().isNotEmpty) {
      rawName = displayName.trim();
    } else if (legacyName != null && legacyName.trim().isNotEmpty) {
      rawName = legacyName.trim();
    }

    // 2. Resolve network (FastAPI sends 'network_type')
    final rawNetwork = json['network_type'] as String? ??
        json['network'] as String? ??
        'Visa';
    final formattedNetwork = _formatNetwork(rawNetwork);

    // 3. Resolve fees (FastAPI sends 'renewal_fee' & 'joining_fee')
    final renewalFee = (json['renewal_fee'] as num?)?.toDouble() ??
        (json['annual_fee'] as num?)?.toDouble() ??
        0.0;
    final joiningFee = (json['joining_fee'] as num?)?.toDouble() ?? 0.0;
    final waiverSpend = (json['fee_waiver_spend'] as num?)?.toDouble();

    // 4. Resolve return rate (FastAPI sends 'return_min_percent')
    final baseReturn = (json['return_min_percent'] as num?)?.toDouble() ??
        (json['base_return_rate'] as num?)?.toDouble() ??
        2.0;

    // 5. Resolve card imagery & bank logo
    final bankLogoUrl = (json['bank_logo_url'] as String?)?.isNotEmpty == true
        ? json['bank_logo_url'] as String
        : (json['bank']?['logo_url'] as String?)?.isNotEmpty == true
            ? json['bank']['logo_url'] as String
            : null;

    final imageUrl = (json['card_image_url'] as String?)?.isNotEmpty == true
        ? json['card_image_url'] as String
        : (json['web_logo_url'] as String?)?.isNotEmpty == true
            ? json['web_logo_url'] as String
            : (json['image_url'] as String?)?.isNotEmpty == true
                ? json['image_url'] as String
                : null;

    // 6. Resolve perks list
    final List<String> perks = [];
    if (json['key_perks'] is List && (json['key_perks'] as List).isNotEmpty) {
      perks.addAll((json['key_perks'] as List).map((e) => e.toString()));
    } else {
      if (json['return_percentage_raw'] != null &&
          json['return_percentage_raw'].toString().isNotEmpty) {
        perks.add('Reward Rate: ${json['return_percentage_raw']}');
      }

      final benefitTypes = json['benefit_types'] as List<dynamic>? ?? [];
      for (final b in benefitTypes) {
        final label = _formatBenefit(b.toString());
        if (label != null && !perks.contains(label)) perks.add(label);
      }

      final loungeTypes = json['lounge_types'] as List<dynamic>? ?? [];
      for (final l in loungeTypes) {
        final label = _formatLounge(l.toString());
        if (label != null && !perks.contains(label)) perks.add(label);
      }

      if (perks.isEmpty && json['overview_text'] != null) {
        perks.add(json['overview_text'].toString());
      }
    }

    // 7. Resolve tabs
    final rawTabs = json['tabs'] as Map<String, dynamic>? ?? {};
    final Map<String, CardTabDetail> parsedTabs = {};

    rawTabs.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedTabs[key] = CardTabDetail(
          title: value['title'] as String? ?? key,
          description: value['description'] as String? ?? '',
          bulletPoints: (value['bullet_points'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
        );
      }
    });

    if (parsedTabs.isEmpty) {
      final loungeTypes = json['lounge_types'] as List<dynamic>? ?? [];
      if (loungeTypes.isNotEmpty) {
        parsedTabs['lounge-access'] = CardTabDetail(
          title: 'Airport Lounge Access',
          description: 'Complimentary airport lounge access privileges',
          bulletPoints: loungeTypes.map((l) => _formatLounge(l.toString()) ?? l.toString()).toList(),
        );
      }

      final benefitTypes = json['benefit_types'] as List<dynamic>? ?? [];
      if (benefitTypes.isNotEmpty) {
        parsedTabs['earn-categories'] = CardTabDetail(
          title: 'Card Multipliers & Privileges',
          description: json['overview_text'] as String? ?? 'Exclusive benefits and partner rewards',
          bulletPoints: benefitTypes.map((b) => _formatBenefit(b.toString()) ?? b.toString()).toList(),
        );
      }
    }

    return CatalogCardModel(
      id: json['id'] as int? ?? 0,
      name: rawName,
      slug: json['slug'] as String? ?? '',
      bankName: (json['bank_name'] as String?)?.trim().isNotEmpty == true
          ? (json['bank_name'] as String).trim()
          : (json['bank']?['name'] as String?)?.trim().isNotEmpty == true
              ? (json['bank']['name'] as String).trim()
              : 'Bank',
      bankSlug: json['bank_slug'] as String? ?? json['bank']?['slug'] as String? ?? '',
      network: formattedNetwork,
      cardType: json['card_type'] as String? ??
          (renewalFee >= 10000
              ? 'Super Premium'
              : renewalFee > 0
                  ? 'Premium'
                  : 'Lifetime Free'),
      annualFee: renewalFee,
      joiningFee: joiningFee,
      feeWaiverSpend: waiverSpend,
      rewardType: json['reward_type'] as String? ?? 'Reward Points',
      baseReturnRate: baseReturn,
      imageUrl: imageUrl,
      bankLogoUrl: bankLogoUrl,
      isPopular: json['is_popular'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.7,
      keyPerks: perks,
      tabs: parsedTabs,
    );
  }

  static String _formatNetwork(String network) {
    final upper = network.toUpperCase();
    if (upper.contains('VISA')) return 'Visa';
    if (upper.contains('MASTER')) return 'Mastercard';
    if (upper.contains('AMEX') || upper.contains('AMERICAN')) return 'American Express';
    if (upper.contains('RUPAY')) return 'RuPay';
    if (upper.contains('DINER')) return 'Diners Club';
    return network;
  }

  static String? _formatBenefit(String benefit) {
    switch (benefit) {
      case 'DINING_ORDER_IN':
        return 'Dining discounts & Swiggy/Zomato benefits';
      case 'TRAVEL':
        return 'Accelerated flight & hotel booking rewards';
      case 'MEMBERSHIP':
        return 'Complimentary premium memberships (Taj, Marriott, EazyDiner)';
      case 'CONCIERGE':
        return '24/7 dedicated luxury concierge assistance';
      case 'GOLF':
        return 'Complimentary golf rounds and coaching sessions';
      case 'MOVIES_AND_EVENTS':
        return '1+1 movie tickets & event entertainment passes';
      case 'SHOPPING':
        return 'Accelerated shopping & e-commerce cashback';
      case 'INSURANCE':
        return 'Comprehensive air accident & emergency medical cover';
      case 'VOUCHERS':
        return 'Welcome vouchers and anniversary gift bonuses';
      default:
        return null;
    }
  }

  static String? _formatLounge(String lounge) {
    switch (lounge) {
      case 'DOMESTIC_LOUNGE':
        return 'Unlimited domestic airport lounge access';
      case 'INTERNATIONAL_LOUNGE':
        return 'Complimentary global lounge access via Priority Pass';
      case 'ADD_ON_CARD_DOMESTIC_LOUNGE':
        return 'Free domestic lounge visits for add-on cardholders';
      case 'ADD_ON_CARD_INTERNATIONAL_LOUNGE':
        return 'Free international lounge visits for add-on members';
      case 'ADD_ON_CARD_LOUNGE':
        return 'Complimentary lounge privileges on add-on cards';
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': name,
        'name': name,
        'slug': slug,
        'bank_name': bankName,
        'bank_slug': bankSlug,
        'network_type': network,
        'network': network,
        'card_type': cardType,
        'renewal_fee': annualFee,
        'annual_fee': annualFee,
        'joining_fee': joiningFee,
        'fee_waiver_spend': feeWaiverSpend,
        'reward_type': rewardType,
        'return_min_percent': baseReturnRate,
        'base_return_rate': baseReturnRate,
        'card_image_url': imageUrl,
        'image_url': imageUrl,
        'bank_logo_url': bankLogoUrl,
        'is_popular': isPopular,
        'rating': rating,
        'key_perks': keyPerks,
      };
}
