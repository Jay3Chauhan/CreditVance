/// Advisor Recommendation domain entity
class RecommendationOption {
  final int cardId;
  final String cardName;
  final String bankName;
  final String network;
  final double returnPercentage;
  final double estimatedValue;
  final String rewardType;
  final String reason;

  const RecommendationOption({
    required this.cardId,
    required this.cardName,
    required this.bankName,
    required this.network,
    required this.returnPercentage,
    required this.estimatedValue,
    required this.rewardType,
    required this.reason,
  });
}

class AdvisorRecommendation {
  final String categorySlug;
  final String categoryName;
  final double spendAmount;
  final bool isInternational;
  final RecommendationOption topCard;
  final List<RecommendationOption> runnersUp;

  const AdvisorRecommendation({
    required this.categorySlug,
    required this.categoryName,
    required this.spendAmount,
    required this.isInternational,
    required this.topCard,
    this.runnersUp = const [],
  });
}
