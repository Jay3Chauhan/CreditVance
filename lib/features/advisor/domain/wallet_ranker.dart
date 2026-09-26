import '../../wallet/domain/entities/user_card.dart';
import 'entities/recommendation.dart';

/// On-device ranking of wallet cards. Used for guests (whose wallet never
/// leaves the device) and as an offline fallback.
///
/// Uses each card's base return rate; international spends are penalised by
/// forex markup plus 18% GST on that markup.
class WalletRanker {
  const WalletRanker._();

  static const double defaultForexMarkup = 3.5;
  static const double defaultBaseRate = 1.0;

  static double effectiveRate(UserCard card, {required bool isInternational}) {
    final base = card.baseReturnRate > 0 ? card.baseReturnRate : defaultBaseRate;
    if (!isInternational) return base;
    final markup = card.forexMarkup ?? defaultForexMarkup;
    return base - markup * 1.18;
  }

  static List<RecommendationOption> rank(
    List<UserCard> cards, {
    required double spend,
    required bool isInternational,
  }) {
    final options = cards.map((c) {
      final rate = effectiveRate(c, isInternational: isInternational);
      final markup = c.forexMarkup ?? defaultForexMarkup;
      return RecommendationOption(
        userCardId: c.id,
        cardId: c.cardId,
        cardName: c.cardName,
        cardSlug: c.cardSlug,
        bankName: c.bankName,
        bankLogoUrl: c.bankLogoUrl,
        imageUrl: c.imageUrl,
        nickname: c.nickname,
        last4Digits: c.last4Digits,
        returnPercentage: double.parse(rate.toStringAsFixed(2)),
        estimatedValue: (spend * rate / 100).roundToDouble(),
        rewardType: 'Rewards',
        reason: isInternational
            ? '${c.baseReturnRate.toStringAsFixed(1)}% base return, ${markup.toStringAsFixed(1)}% forex markup'
            : '${c.baseReturnRate.toStringAsFixed(1)}% base return on this spend',
      );
    }).toList()
      ..sort((a, b) => b.returnPercentage.compareTo(a.returnPercentage));
    return options;
  }
}
