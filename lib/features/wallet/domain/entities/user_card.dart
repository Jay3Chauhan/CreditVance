/// A card in the user's wallet.
///
/// Holds only non-sensitive metadata. PAN / CVV / expiry live exclusively in
/// the hardware-backed vault.
class UserCard {
  final int id;
  final int cardId;
  final String nickname;
  final String last4Digits;
  final int? billingCycleDay;
  final String cardName;
  final String? cardSlug;
  final String bankName;
  final String network;
  final double annualFee;
  final double baseReturnRate;
  final double? maxReturnRate;
  final double? forexMarkup;
  final String? imageUrl;
  final String? bankLogoUrl;
  final bool hasVaultDetails;
  final DateTime? addedAt;

  const UserCard({
    required this.id,
    required this.cardId,
    required this.nickname,
    required this.last4Digits,
    this.billingCycleDay,
    required this.cardName,
    this.cardSlug,
    required this.bankName,
    required this.network,
    this.annualFee = 0.0,
    this.baseReturnRate = 1.0,
    this.maxReturnRate,
    this.forexMarkup,
    this.imageUrl,
    this.bankLogoUrl,
    this.hasVaultDetails = false,
    this.addedAt,
  });

  /// Next statement date based on [billingCycleDay].
  DateTime? get nextStatementDate {
    final day = billingCycleDay;
    if (day == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var date = DateTime(now.year, now.month, day);
    if (date.isBefore(today)) date = DateTime(now.year, now.month + 1, day);
    return date;
  }

  /// Most Indian issuers give ~18 days after the statement to pay.
  DateTime? get estimatedDueDate => nextStatementDate?.add(const Duration(days: 18));

  UserCard copyWith({
    int? id,
    String? nickname,
    String? last4Digits,
    int? billingCycleDay,
    bool? hasVaultDetails,
  }) {
    return UserCard(
      id: id ?? this.id,
      cardId: cardId,
      nickname: nickname ?? this.nickname,
      last4Digits: last4Digits ?? this.last4Digits,
      billingCycleDay: billingCycleDay ?? this.billingCycleDay,
      cardName: cardName,
      cardSlug: cardSlug,
      bankName: bankName,
      network: network,
      annualFee: annualFee,
      baseReturnRate: baseReturnRate,
      maxReturnRate: maxReturnRate,
      forexMarkup: forexMarkup,
      imageUrl: imageUrl,
      bankLogoUrl: bankLogoUrl,
      hasVaultDetails: hasVaultDetails ?? this.hasVaultDetails,
      addedAt: addedAt,
    );
  }
}
