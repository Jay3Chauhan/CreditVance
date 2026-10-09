import 'card_transaction.dart';
import 'spend_category.dart';

/// Selectable analytics window.
enum AnalyticsPeriod {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last3Months('3 Months'),
  last6Months('6 Months'),
  thisYear('This Year');

  const AnalyticsPeriod(this.label);
  final String label;
}

/// Net spend for one category within the period.
class CategorySpend {
  final SpendCategory category;
  final double amount;
  final int count;

  /// Share of total net spend in the range 0..1.
  final double share;

  const CategorySpend({
    required this.category,
    required this.amount,
    required this.count,
    required this.share,
  });
}

/// Net spend for one physical card (keyed by last 4 digits).
class CardSpend {
  final String? cardLast4;
  final int? userCardId;
  final String label;
  final String bankName;
  final double amount;
  final int count;
  final double share;

  /// Latest available limit reported by an alert for this card.
  final double? latestAvailableLimit;

  const CardSpend({
    required this.cardLast4,
    required this.userCardId,
    required this.label,
    required this.bankName,
    required this.amount,
    required this.count,
    required this.share,
    this.latestAvailableLimit,
  });

  /// True when the card is not saved in the user's vault.
  bool get isUnlinked => userCardId == null;
}

/// Net spend at one normalised merchant.
class MerchantSpend {
  final String merchantName;
  final SpendCategory category;
  final double amount;
  final int count;

  const MerchantSpend({
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.count,
  });
}

/// Net spend for one calendar month (trend chart bar).
class MonthlySpend {
  final DateTime month;
  final double amount;

  const MonthlySpend({required this.month, required this.amount});
}

/// Aggregated spend analytics for a period, computed on-device.
class SpendAnalytics {
  final AnalyticsPeriod period;
  final DateTime start;
  final DateTime end;

  /// Debits minus refunds/reversals.
  final double netSpend;
  final double grossSpend;
  final double refunds;
  final double previousPeriodSpend;
  final int debitCount;
  final double feesAndCharges;

  /// Foreign-currency debits in the period. These are excluded from INR
  /// totals until the backend enriches them with the billed INR amount.
  final int internationalCount;
  final List<CategorySpend> byCategory;
  final List<CardSpend> byCard;
  final List<MerchantSpend> topMerchants;
  final List<MonthlySpend> monthlyTrend;

  /// Unusually large debits relative to the user's own baseline.
  final List<CardTransaction> unusualTransactions;

  const SpendAnalytics({
    required this.period,
    required this.start,
    required this.end,
    required this.netSpend,
    required this.grossSpend,
    required this.refunds,
    required this.previousPeriodSpend,
    required this.debitCount,
    required this.feesAndCharges,
    required this.internationalCount,
    required this.byCategory,
    required this.byCard,
    required this.topMerchants,
    required this.monthlyTrend,
    required this.unusualTransactions,
  });

  /// Empty analytics for a period with no data.
  factory SpendAnalytics.empty(AnalyticsPeriod period, DateTime start, DateTime end) {
    return SpendAnalytics(
      period: period,
      start: start,
      end: end,
      netSpend: 0,
      grossSpend: 0,
      refunds: 0,
      previousPeriodSpend: 0,
      debitCount: 0,
      feesAndCharges: 0,
      internationalCount: 0,
      byCategory: const [],
      byCard: const [],
      topMerchants: const [],
      monthlyTrend: const [],
      unusualTransactions: const [],
    );
  }

  double get averageTicket => debitCount == 0 ? 0 : grossSpend / debitCount;

  /// Fractional change vs. the previous equal-length period (null when no baseline).
  double? get changeVsPrevious =>
      previousPeriodSpend <= 0 ? null : (netSpend - previousPeriodSpend) / previousPeriodSpend;
}
