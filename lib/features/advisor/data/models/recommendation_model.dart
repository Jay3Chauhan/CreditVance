import '../../domain/entities/recommendation.dart';

/// DTO for AdvisorRecommendation supporting FastAPI response schema and offline mocks
class AdvisorRecommendationModel extends AdvisorRecommendation {
  const AdvisorRecommendationModel({
    required super.categorySlug,
    required super.categoryName,
    required super.spendAmount,
    required super.isInternational,
    required super.topCard,
    super.runnersUp,
  });

  factory AdvisorRecommendationModel.fromJson(Map<String, dynamic> json) {
    // Backend returns 'top_recommendation' (if user cards exist) or 'market_benchmark_card'
    final topCardJson = (json['top_recommendation'] as Map<String, dynamic>?) ??
        (json['market_benchmark_card'] as Map<String, dynamic>?) ??
        (json['top_card'] as Map<String, dynamic>?) ??
        {};

    final runnersUpList = (json['alternative_cards'] as List<dynamic>?) ??
        (json['runners_up'] as List<dynamic>?) ??
        [];

    final topOption = _parseOption(topCardJson, defaultId: 1, defaultName: 'HDFC Infinia Metal');
    final alternatives = runnersUpList
        .map((e) => _parseOption(e as Map<String, dynamic>, defaultId: 2, defaultName: 'SBI Cashback'))
        .toList();

    return AdvisorRecommendationModel(
      categorySlug: json['category_slug'] as String? ?? 'dining',
      categoryName: json['category_name'] as String? ?? json['category_slug'] as String? ?? 'Dining',
      spendAmount: (json['spend_amount'] as num?)?.toDouble() ?? 5000.0,
      isInternational: json['is_international'] as bool? ?? false,
      topCard: topOption,
      runnersUp: alternatives,
    );
  }

  static RecommendationOption _parseOption(Map<String, dynamic> m, {required int defaultId, required String defaultName}) {
    final rawName = m['card_title'] as String? ??
        m['card_name'] as String? ??
        m['title'] as String? ??
        defaultName;

    final returnPercent = (m['effective_return_percent'] as num?)?.toDouble() ??
        (m['return_percentage'] as num?)?.toDouble() ??
        5.0;

    final estimatedVal = (m['estimated_reward_value_inr'] as num?)?.toDouble() ??
        (m['estimated_value'] as num?)?.toDouble() ??
        (returnPercent > 0 ? (5000.0 * (returnPercent / 100)) : 250.0);

    final reason = m['benefit_highlight'] as String? ??
        m['reason'] as String? ??
        'Maximum rewards and accelerated multipliers for this category.';

    return RecommendationOption(
      cardId: m['card_id'] as int? ?? defaultId,
      cardName: rawName,
      bankName: m['bank_name'] as String? ?? 'Bank',
      network: m['network_type'] as String? ?? m['network'] as String? ?? 'Visa',
      returnPercentage: returnPercent,
      estimatedValue: estimatedVal,
      rewardType: m['reward_type'] as String? ?? 'Reward Points',
      reason: reason,
    );
  }
}
