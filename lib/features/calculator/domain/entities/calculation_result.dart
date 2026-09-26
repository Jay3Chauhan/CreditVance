/// Spend buckets used by the annual rewards simulator.
enum SpendBucket {
  dining('Dining', 'Dining'),
  travel('Travel & flights', 'Travel'),
  grocery('Groceries', 'Grocery'),
  shopping('Online shopping', 'Online Shopping'),
  bills('Bills & utilities', 'Utilities'),
  other('Everything else', 'Offline Spends');

  final String label;
  final String categorySlug;
  const SpendBucket(this.label, this.categorySlug);
}

/// The card being simulated — built from a catalog card or a wallet card.
class RewardSubject {
  final int cardId;
  final int? userCardId;
  final String name;
  final String? slug;
  final String bankName;
  final String? bankLogoUrl;
  final double baseRate;
  final double? maxRate;
  final double annualFee;
  final double? feeWaiverSpend;

  const RewardSubject({
    required this.cardId,
    this.userCardId,
    required this.name,
    this.slug,
    required this.bankName,
    this.bankLogoUrl,
    required this.baseRate,
    this.maxRate,
    required this.annualFee,
    this.feeWaiverSpend,
  });
}

class CategoryRewardBreakdown {
  final SpendBucket bucket;
  final double spend;
  final double returnPercentage;
  final double earnedRupees;

  const CategoryRewardBreakdown({
    required this.bucket,
    required this.spend,
    required this.returnPercentage,
    required this.earnedRupees,
  });
}

class CalculationResult {
  final RewardSubject subject;
  final double annualSpend;
  final double annualFee;
  final bool feeWaived;
  final double totalRewardValue;
  final double netBenefit;
  final double effectiveRoi;
  final List<CategoryRewardBreakdown> breakdowns;

  const CalculationResult({
    required this.subject,
    required this.annualSpend,
    required this.annualFee,
    required this.feeWaived,
    required this.totalRewardValue,
    required this.netBenefit,
    required this.effectiveRoi,
    this.breakdowns = const [],
  });
}
