import '../../domain/entities/recommendation.dart';

/// Parses `POST /advisor/recommend` (`CardRecommendationResponse`).
class AdvisorRecommendationModel {
  const AdvisorRecommendationModel._();

  static AdvisorRecommendation fromJson(
    Map<String, dynamic> json, {
    required bool isInternational,
  }) {
    final top = json['top_recommendation'];
    final benchmark = json['market_benchmark_card'];
    final alternatives = (json['alternative_cards'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(optionFromJson)
        .toList();

    return AdvisorRecommendation(
      categorySlug: json['category_slug'] as String? ?? '',
      spendAmount: (json['spend_amount'] as num?)?.toDouble() ?? 0,
      isInternational: isInternational,
      topCard: top is Map<String, dynamic> ? optionFromJson(top) : null,
      alternatives: alternatives,
      marketBest: benchmark is Map<String, dynamic> ? optionFromJson(benchmark) : null,
      insights: (json['insights'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
    );
  }

  static RecommendationOption optionFromJson(Map<String, dynamic> m) {
    final rewardType = m['reward_type']?.toString() ?? 'points';
    return RecommendationOption(
      userCardId: (m['user_card_id'] as num?)?.toInt(),
      cardId: (m['card_id'] as num?)?.toInt() ?? 0,
      cardName: m['card_title'] as String? ?? m['card_name'] as String? ?? 'Card',
      cardSlug: m['card_slug'] as String?,
      bankName: m['bank_name'] as String? ?? '',
      bankLogoUrl: m['bank_logo_url'] as String?,
      imageUrl: m['card_image_url'] as String?,
      nickname: m['nickname'] as String?,
      last4Digits: m['last_4_digits'] as String?,
      returnPercentage: (m['effective_return_percent'] as num?)?.toDouble() ?? 0,
      estimatedValue: (m['estimated_reward_value_inr'] as num?)?.toDouble() ?? 0,
      estimatedPoints: (m['estimated_reward_points'] as num?)?.toDouble(),
      rewardType: _rewardLabel(rewardType),
      reason: m['benefit_highlight'] as String? ?? '',
      notes: m['notes_or_exclusions'] as String?,
    );
  }

  static String _rewardLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'points':
      case 'reward_points':
        return 'Reward points';
      case 'cashback':
        return 'Cashback';
      case 'miles':
        return 'Air miles';
      default:
        return raw.isEmpty ? 'Rewards' : raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');
    }
  }
}
