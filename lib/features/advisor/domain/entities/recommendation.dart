/// A single ranked card suggestion for a purchase.
class RecommendationOption {
  final int? userCardId;
  final int cardId;
  final String cardName;
  final String? cardSlug;
  final String bankName;
  final String? bankLogoUrl;
  final String? imageUrl;
  final String? nickname;
  final String? last4Digits;
  final double returnPercentage;
  final double estimatedValue;
  final double? estimatedPoints;
  final String rewardType;
  final String reason;
  final String? notes;

  const RecommendationOption({
    this.userCardId,
    required this.cardId,
    required this.cardName,
    this.cardSlug,
    required this.bankName,
    this.bankLogoUrl,
    this.imageUrl,
    this.nickname,
    this.last4Digits,
    required this.returnPercentage,
    required this.estimatedValue,
    this.estimatedPoints,
    required this.rewardType,
    required this.reason,
    this.notes,
  });

  bool get isInWallet => userCardId != null;
}

/// Where the ranking came from.
enum RecommendationSource { server, onDevice }

class AdvisorRecommendation {
  final String categorySlug;
  final double spendAmount;
  final bool isInternational;
  final RecommendationOption? topCard;
  final List<RecommendationOption> alternatives;
  final RecommendationOption? marketBest;
  final List<String> insights;
  final RecommendationSource source;

  const AdvisorRecommendation({
    required this.categorySlug,
    required this.spendAmount,
    required this.isInternational,
    this.topCard,
    this.alternatives = const [],
    this.marketBest,
    this.insights = const [],
    this.source = RecommendationSource.server,
  });

  bool get hasWalletPick => topCard != null;

  /// Extra value the market-best card would earn over the wallet's best pick.
  double get missedValue {
    if (topCard == null || marketBest == null) return 0;
    final diff = marketBest!.estimatedValue - topCard!.estimatedValue;
    return diff > 0 ? diff : 0;
  }

  AdvisorRecommendation copyWith({
    RecommendationOption? topCard,
    List<RecommendationOption>? alternatives,
    List<String>? insights,
    RecommendationSource? source,
  }) {
    return AdvisorRecommendation(
      categorySlug: categorySlug,
      spendAmount: spendAmount,
      isInternational: isInternational,
      topCard: topCard ?? this.topCard,
      alternatives: alternatives ?? this.alternatives,
      marketBest: marketBest,
      insights: insights ?? this.insights,
      source: source ?? this.source,
    );
  }
}
