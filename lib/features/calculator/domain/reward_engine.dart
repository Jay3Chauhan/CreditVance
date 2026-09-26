import 'entities/calculation_result.dart';

/// On-device annual reward simulator.
///
/// Uses the card's base return rate per bucket, with curated accelerated
/// rates for a few well-known cards. Real per-category rates need the
/// backend's multi-category calculator (see docs/BACKEND_REQUIREMENTS.md).
class RewardEngine {
  const RewardEngine._();

  static const Map<String, Map<SpendBucket, double>> _curated = {
    'infinia': {
      SpendBucket.dining: 10.0,
      SpendBucket.travel: 16.5,
      SpendBucket.shopping: 3.3,
      SpendBucket.grocery: 3.3,
      SpendBucket.bills: 3.3,
      SpendBucket.other: 3.3,
    },
    'sbi-cashback': {
      SpendBucket.dining: 5.0,
      SpendBucket.travel: 5.0,
      SpendBucket.shopping: 5.0,
      SpendBucket.grocery: 5.0,
      SpendBucket.bills: 0.0,
      SpendBucket.other: 1.0,
    },
    'atlas': {
      SpendBucket.travel: 10.0,
    },
    'amazon-pay': {
      SpendBucket.shopping: 5.0,
      SpendBucket.dining: 2.0,
      SpendBucket.bills: 2.0,
      SpendBucket.other: 1.0,
    },
  };

  static double rateFor(RewardSubject s, SpendBucket bucket) {
    final slug = (s.slug ?? s.name).toLowerCase();
    for (final entry in _curated.entries) {
      if (slug.contains(entry.key)) {
        final r = entry.value[bucket];
        if (r != null) return r;
      }
    }
    return s.baseRate > 0 ? s.baseRate : 1.0;
  }

  static CalculationResult calculate(RewardSubject subject, Map<SpendBucket, double> monthly) {
    final breakdowns = <CategoryRewardBreakdown>[];
    var totalSpend = 0.0;
    var totalEarned = 0.0;

    for (final bucket in SpendBucket.values) {
      final annual = (monthly[bucket] ?? 0) * 12;
      final rate = rateFor(subject, bucket);
      final earned = (annual * rate / 100).roundToDouble();
      totalSpend += annual;
      totalEarned += earned;
      breakdowns.add(CategoryRewardBreakdown(
        bucket: bucket,
        spend: annual,
        returnPercentage: rate,
        earnedRupees: earned,
      ));
    }

    final waiver = subject.feeWaiverSpend;
    final waived = subject.annualFee > 0 && waiver != null && totalSpend >= waiver;
    final fee = waived ? 0.0 : subject.annualFee;
    final net = totalEarned - fee;

    return CalculationResult(
      subject: subject,
      annualSpend: totalSpend,
      annualFee: fee,
      feeWaived: waived,
      totalRewardValue: totalEarned,
      netBenefit: net,
      effectiveRoi: totalSpend > 0 ? net / totalSpend * 100 : 0,
      breakdowns: breakdowns,
    );
  }
}
