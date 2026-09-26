import '../../../catalog/data/models/catalog_card_model.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../domain/entities/user_card.dart';

/// DTO for [UserCard]. Serializes non-sensitive metadata only.
class UserCardModel extends UserCard {
  const UserCardModel({
    required super.id,
    required super.cardId,
    required super.nickname,
    required super.last4Digits,
    super.billingCycleDay,
    required super.cardName,
    super.cardSlug,
    required super.bankName,
    required super.network,
    super.annualFee,
    super.baseReturnRate,
    super.maxReturnRate,
    super.forexMarkup,
    super.imageUrl,
    super.bankLogoUrl,
    super.hasVaultDetails,
    super.addedAt,
  });

  factory UserCardModel.fromJson(Map<String, dynamic> json) {
    final rawCard = json['card'] is Map<String, dynamic> ? json['card'] as Map<String, dynamic> : null;
    final catalog = rawCard != null ? CatalogCardModel.fromJson(rawCard) : null;

    return UserCardModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cardId: (json['card_id'] as num?)?.toInt() ?? catalog?.id ?? 0,
      nickname: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? json['nickname'] as String
          : (catalog?.shortName ?? 'My card'),
      last4Digits: json['last_4_digits'] as String? ?? '••••',
      billingCycleDay: (json['billing_cycle_day'] as num?)?.toInt(),
      cardName: json['card_name'] as String? ?? catalog?.name ?? 'Credit Card',
      cardSlug: json['card_slug'] as String? ?? catalog?.slug,
      bankName: json['bank_name'] as String? ?? catalog?.bankName ?? 'Bank',
      network: json['network'] as String? ?? catalog?.network ?? 'Visa',
      annualFee: (json['annual_fee'] as num?)?.toDouble() ?? catalog?.annualFee ?? 0.0,
      baseReturnRate: (json['base_return_rate'] as num?)?.toDouble() ?? catalog?.baseReturnRate ?? 1.0,
      maxReturnRate: (json['max_return_rate'] as num?)?.toDouble() ?? catalog?.maxReturnRate,
      forexMarkup: (json['forex_markup'] as num?)?.toDouble() ?? catalog?.forexMarkup,
      imageUrl: json['image_url'] as String? ?? catalog?.imageUrl,
      bankLogoUrl: json['bank_logo_url'] as String? ?? catalog?.bankLogoUrl,
      hasVaultDetails: json['has_vault_details'] as bool? ?? false,
      addedAt: DateTime.tryParse(json['added_at'] as String? ?? ''),
    );
  }

  factory UserCardModel.fromCatalog({
    required int id,
    required CatalogCard card,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    bool hasVaultDetails = false,
  }) {
    return UserCardModel(
      id: id,
      cardId: card.id,
      nickname: nickname,
      last4Digits: last4Digits,
      billingCycleDay: billingCycleDay,
      cardName: card.name,
      cardSlug: card.slug,
      bankName: card.bankName,
      network: card.network,
      annualFee: card.annualFee,
      baseReturnRate: card.baseReturnRate,
      maxReturnRate: card.maxReturnRate,
      forexMarkup: card.forexMarkup,
      imageUrl: card.imageUrl,
      bankLogoUrl: card.bankLogoUrl,
      hasVaultDetails: hasVaultDetails,
      addedAt: DateTime.now(),
    );
  }

  factory UserCardModel.fromEntity(UserCard c) => UserCardModel(
        id: c.id,
        cardId: c.cardId,
        nickname: c.nickname,
        last4Digits: c.last4Digits,
        billingCycleDay: c.billingCycleDay,
        cardName: c.cardName,
        cardSlug: c.cardSlug,
        bankName: c.bankName,
        network: c.network,
        annualFee: c.annualFee,
        baseReturnRate: c.baseReturnRate,
        maxReturnRate: c.maxReturnRate,
        forexMarkup: c.forexMarkup,
        imageUrl: c.imageUrl,
        bankLogoUrl: c.bankLogoUrl,
        hasVaultDetails: c.hasVaultDetails,
        addedAt: c.addedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'card_id': cardId,
        'nickname': nickname,
        'last_4_digits': last4Digits,
        'billing_cycle_day': billingCycleDay,
        'card_name': cardName,
        'card_slug': cardSlug,
        'bank_name': bankName,
        'network': network,
        'annual_fee': annualFee,
        'base_return_rate': baseReturnRate,
        'max_return_rate': maxReturnRate,
        'forex_markup': forexMarkup,
        'image_url': imageUrl,
        'bank_logo_url': bankLogoUrl,
        'has_vault_details': hasVaultDetails,
        'added_at': addedAt?.toIso8601String(),
      };
}
