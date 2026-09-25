import '../../domain/entities/calculation_result.dart';

/// DTO for CalculationResult supporting FastAPI calculate schema and offline simulator
class CalculationResultModel extends CalculationResult {
  const CalculationResultModel({
    required super.cardId,
    required super.cardName,
    required super.bankName,
    required super.annualSpend,
    required super.annualFee,
    required super.totalRewardValue,
    required super.netBenefit,
    required super.effectiveRoi,
    super.breakdowns,
  });

  factory CalculationResultModel.fromJson(Map<String, dynamic> json) {
    final breakdownList = (json['breakdowns'] as List<dynamic>?) ?? [];

    final suggestedCard = json['suggested_card'] as Map<String, dynamic>?;
    final userCard = json['user_card'] as Map<String, dynamic>?;

    final cardName = suggestedCard?['card_name'] as String? ??
        userCard?['card_name'] as String? ??
        json['card_name'] as String? ??
        'HDFC Infinia Metal';

    final bankName = suggestedCard?['bank_name'] as String? ??
        userCard?['bank_name'] as String? ??
        json['bank_name'] as String? ??
        'HDFC Bank';

    final cardId = suggestedCard?['card_id'] as int? ??
        userCard?['card_id'] as int? ??
        json['card_id'] as int? ??
        1;

    final totalRewardVal = (suggestedCard?['reward_worth'] as num?)?.toDouble() ??
        (userCard?['reward_worth'] as num?)?.toDouble() ??
        (json['total_reward_value'] as num?)?.toDouble() ??
        42000.0;

    final netBenefitVal = (json['annual_savings'] as num?)?.toDouble() ??
        (json['net_benefit'] as num?)?.toDouble() ??
        29500.0;

    final roi = (suggestedCard?['return_percentage'] as num?)?.toDouble() ??
        (userCard?['return_percentage'] as num?)?.toDouble() ??
        (json['effective_roi'] as num?)?.toDouble() ??
        7.0;

    return CalculationResultModel(
      cardId: cardId,
      cardName: cardName,
      bankName: bankName,
      annualSpend: (json['annual_spend'] as num?)?.toDouble() ?? 600000.0,
      annualFee: (json['annual_fee'] as num?)?.toDouble() ?? 0.0,
      totalRewardValue: totalRewardVal,
      netBenefit: netBenefitVal,
      effectiveRoi: roi,
      breakdowns: breakdownList.map((e) {
        final m = e as Map<String, dynamic>;
        return CategoryRewardBreakdown(
          categoryName: m['category_name'] as String? ?? 'General',
          spend: (m['spend'] as num?)?.toDouble() ?? 0.0,
          returnPercentage: (m['return_percentage'] as num?)?.toDouble() ?? 3.3,
          earnedRupees: (m['earned_rupees'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
    );
  }
}
