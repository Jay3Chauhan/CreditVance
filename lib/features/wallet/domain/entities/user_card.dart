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
  final int? dueDay;
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
    this.dueDay,
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
  DateTime? get nextStatementDate => _nextMonthDay(billingCycleDay);

  /// Payment due date. Uses [dueDay] from the server when set, otherwise
  /// about 18 days after the statement. Day 31 lands on the month's last day.
  DateTime? get estimatedDueDate => dueDay != null ? _nextMonthDay(dueDay) : nextStatementDate?.add(const Duration(days: 18));

  static DateTime? _nextMonthDay(int? day) {
    if (day == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime on(int year, int month) {
      final last = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, day.clamp(1, last));
    }

    var date = on(now.year, now.month);
    if (date.isBefore(today)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      date = on(nextYear, nextMonth);
    }
    return date;
  }

  UserCard copyWith({
    int? id,
    String? nickname,
    String? last4Digits,
    int? billingCycleDay,
    int? dueDay,
    bool? hasVaultDetails,
  }) {
    return UserCard(
      id: id ?? this.id,
      cardId: cardId,
      nickname: nickname ?? this.nickname,
      last4Digits: last4Digits ?? this.last4Digits,
      billingCycleDay: billingCycleDay ?? this.billingCycleDay,
      dueDay: dueDay ?? this.dueDay,
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
