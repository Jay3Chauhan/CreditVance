/// User portfolio card entity.
/// Sensitive PAN and CVV are stored solely in hardware Secure Enclave.
class UserCard {
  final int id;
  final int cardId;
  final String nickname;
  final String last4Digits;
  final int? billingCycleDay;
  final String cardName;
  final String bankName;
  final String network;
  final double annualFee;
  final String? imageUrl;
  final String? bankLogoUrl;
  final bool hasVaultDetails;

  const UserCard({
    required this.id,
    required this.cardId,
    required this.nickname,
    required this.last4Digits,
    this.billingCycleDay,
    required this.cardName,
    required this.bankName,
    required this.network,
    this.annualFee = 0.0,
    this.imageUrl,
    this.bankLogoUrl,
    this.hasVaultDetails = false,
  });

  UserCard copyWith({
    int? id,
    int? cardId,
    String? nickname,
    String? last4Digits,
    int? billingCycleDay,
    String? cardName,
    String? bankName,
    String? network,
    double? annualFee,
    String? imageUrl,
    String? bankLogoUrl,
    bool? hasVaultDetails,
  }) {
    return UserCard(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      nickname: nickname ?? this.nickname,
      last4Digits: last4Digits ?? this.last4Digits,
      billingCycleDay: billingCycleDay ?? this.billingCycleDay,
      cardName: cardName ?? this.cardName,
      bankName: bankName ?? this.bankName,
      network: network ?? this.network,
      annualFee: annualFee ?? this.annualFee,
      imageUrl: imageUrl ?? this.imageUrl,
      bankLogoUrl: bankLogoUrl ?? this.bankLogoUrl,
      hasVaultDetails: hasVaultDetails ?? this.hasVaultDetails,
    );
  }
}
