/// Reward Calculation Domain Entity
class CategoryRewardBreakdown {
  final String categoryName;
  final double spend;
  final double returnPercentage;
  final double earnedRupees;

  const CategoryRewardBreakdown({
    required this.categoryName,
    required this.spend,
    required this.returnPercentage,
    required this.earnedRupees,
  });
}

class CalculationResult {
  final int cardId;
  final String cardName;
  final String bankName;
  final double annualSpend;
  final double annualFee;
  final double totalRewardValue;
  final double netBenefit;
  final double effectiveRoi;
  final List<CategoryRewardBreakdown> breakdowns;

  const CalculationResult({
    required this.cardId,
    required this.cardName,
    required this.bankName,
    required this.annualSpend,
    required this.annualFee,
    required this.totalRewardValue,
    required this.netBenefit,
    required this.effectiveRoi,
    this.breakdowns = const [],
  });
}
