import '../../domain/entities/user_card.dart';

/// DTO for UserCard entity
class UserCardModel extends UserCard {
  const UserCardModel({
    required super.id,
    required super.cardId,
    required super.nickname,
    required super.last4Digits,
    super.billingCycleDay,
    required super.cardName,
    required super.bankName,
    required super.network,
    super.annualFee,
    super.imageUrl,
    super.bankLogoUrl,
    super.hasVaultDetails,
  });

  factory UserCardModel.fromJson(Map<String, dynamic> json) {
    final rawCard = json['card'] as Map<String, dynamic>?;

    final resolvedCardName = json['card_name'] as String? ??
        rawCard?['title'] as String? ??
        rawCard?['display_name'] as String? ??
        rawCard?['name'] as String? ??
        'Credit Card';

    final resolvedBankName = json['bank_name'] as String? ??
        rawCard?['bank_name'] as String? ??
        rawCard?['bank']?['name'] as String? ??
        'Bank';

    final resolvedNetwork = json['network'] as String? ??
        rawCard?['network_type'] as String? ??
        rawCard?['network'] as String? ??
        'Visa';

    final resolvedImageUrl = json['image_url'] as String? ??
        rawCard?['card_image_url'] as String? ??
        rawCard?['web_logo_url'] as String? ??
        rawCard?['image_url'] as String?;

    final resolvedBankLogoUrl = json['bank_logo_url'] as String? ??
        rawCard?['bank_logo_url'] as String? ??
        rawCard?['bank']?['logo_url'] as String?;

    return UserCardModel(
      id: json['id'] as int? ?? 0,
      cardId: json['card_id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? 'My Card',
      last4Digits: json['last_4_digits'] as String? ?? '0000',
      billingCycleDay: json['billing_cycle_day'] as int?,
      cardName: resolvedCardName,
      bankName: resolvedBankName,
      network: resolvedNetwork,
      annualFee: (json['annual_fee'] as num?)?.toDouble() ??
          (rawCard?['renewal_fee'] as num?)?.toDouble() ??
          (rawCard?['annual_fee'] as num?)?.toDouble() ??
          0.0,
      imageUrl: resolvedImageUrl,
      bankLogoUrl: resolvedBankLogoUrl,
      hasVaultDetails: json['has_vault_details'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'card_id': cardId,
        'nickname': nickname,
        'last_4_digits': last4Digits,
        'billing_cycle_day': billingCycleDay,
        'card_name': cardName,
        'bank_name': bankName,
        'network': network,
        'annual_fee': annualFee,
        'image_url': imageUrl,
        'bank_logo_url': bankLogoUrl,
      };
}
