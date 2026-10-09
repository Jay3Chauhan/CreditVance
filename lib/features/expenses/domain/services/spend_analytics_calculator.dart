import '../entities/card_transaction.dart';
import '../entities/spend_analytics.dart';
import '../entities/spend_category.dart';
import '../entities/tracked_card_ref.dart';

/// Pure, on-device aggregation of parsed transactions into [SpendAnalytics].
///
/// Totals are INR only; foreign-currency debits are counted separately.
class SpendAnalyticsCalculator {
  const SpendAnalyticsCalculator();

  static const int trendMonths = 6;
  static const int topMerchantCount = 8;

  /// Returns the half-open `[start, end)` window for [period] relative to [now].
  static (DateTime, DateTime) rangeFor(AnalyticsPeriod period, DateTime now) {
    final y = now.year;
    final m = now.month;
    switch (period) {
      case AnalyticsPeriod.thisMonth:
        return (DateTime(y, m), DateTime(y, m + 1));
      case AnalyticsPeriod.lastMonth:
        return (DateTime(y, m - 1), DateTime(y, m));
      case AnalyticsPeriod.last3Months:
        return (DateTime(y, m - 2), DateTime(y, m + 1));
      case AnalyticsPeriod.last6Months:
        return (DateTime(y, m - 5), DateTime(y, m + 1));
      case AnalyticsPeriod.thisYear:
        return (DateTime(y), DateTime(y + 1));
    }
  }

  /// Equal-length window immediately preceding [period] (for the change badge).
  static (DateTime, DateTime) previousRangeFor(AnalyticsPeriod period, DateTime now) {
    final (start, end) = rangeFor(period, now);
    if (period == AnalyticsPeriod.thisYear) return (DateTime(start.year - 1), start);
    final months = (end.year - start.year) * 12 + end.month - start.month;
    return (DateTime(start.year, start.month - months), start);
  }

  static bool _inRange(DateTime t, DateTime start, DateTime end) => !t.isBefore(start) && t.isBefore(end);

  /// Computes analytics for [period] over [transactions].
  SpendAnalytics compute({
    required List<CardTransaction> transactions,
    required AnalyticsPeriod period,
    List<TrackedCardRef> cards = const [],
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final (start, end) = rangeFor(period, clock);
    final (prevStart, prevEnd) = previousRangeFor(period, clock);

    final inr = transactions.where((t) => !t.isInternational && t.type.affectsSpend).toList();
    final current = inr.where((t) => _inRange(t.occurredAt, start, end)).toList();
    final internationalCount = transactions
        .where((t) => t.isInternational && t.type == TransactionType.debit && _inRange(t.occurredAt, start, end))
        .length;

    final debits = current.where((t) => t.type == TransactionType.debit).toList();
    final gross = debits.fold<double>(0, (a, t) => a + t.amount);
    final refunds = current.where((t) => t.type != TransactionType.debit).fold<double>(0, (a, t) => a + t.amount);
    final net = gross - refunds;

    return SpendAnalytics(
      period: period,
      start: start,
      end: end,
      netSpend: net,
      grossSpend: gross,
      refunds: refunds,
      previousPeriodSpend: _net(inr.where((t) => _inRange(t.occurredAt, prevStart, prevEnd))),
      debitCount: debits.length,
      feesAndCharges:
          debits.where((t) => t.category == SpendCategory.fees).fold<double>(0, (a, t) => a + t.amount),
      internationalCount: internationalCount,
      byCategory: _byCategory(current, net),
      byCard: _byCard(current, transactions, cards, net),
      topMerchants: _topMerchants(current),
      monthlyTrend: _monthlyTrend(inr, _earlier(end, DateTime(clock.year, clock.month + 1))),
      unusualTransactions: _unusual(debits, inr, clock),
    );
  }

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  static double _net(Iterable<CardTransaction> txns) => txns.fold<double>(0, (a, t) => a + t.signedSpend);

  List<CategorySpend> _byCategory(List<CardTransaction> txns, double net) {
    final amounts = <SpendCategory, double>{};
    final counts = <SpendCategory, int>{};
    for (final t in txns) {
      amounts[t.category] = (amounts[t.category] ?? 0) + t.signedSpend;
      if (t.type == TransactionType.debit) counts[t.category] = (counts[t.category] ?? 0) + 1;
    }
    final list = [
      for (final e in amounts.entries)
        if (e.value > 0)
          CategorySpend(
            category: e.key,
            amount: e.value,
            count: counts[e.key] ?? 0,
            share: net > 0 ? (e.value / net).clamp(0.0, 1.0) : 0,
          ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  List<CardSpend> _byCard(
    List<CardTransaction> txns,
    List<CardTransaction> all,
    List<TrackedCardRef> cards,
    double net,
  ) {
    final amounts = <String, double>{};
    final counts = <String, int>{};
    final samples = <String, CardTransaction>{};
    String keyOf(CardTransaction t) => '${t.bankCode}|${t.cardLast4 ?? '----'}';

    for (final t in txns) {
      final k = keyOf(t);
      amounts[k] = (amounts[k] ?? 0) + t.signedSpend;
      if (t.type == TransactionType.debit) counts[k] = (counts[k] ?? 0) + 1;
      samples.putIfAbsent(k, () => t);
    }

    final latestLimit = <String, CardTransaction>{};
    for (final t in all) {
      if (t.availableLimit == null) continue;
      final k = keyOf(t);
      final existing = latestLimit[k];
      if (existing == null || t.occurredAt.isAfter(existing.occurredAt)) latestLimit[k] = t;
    }

    final list = <CardSpend>[];
    for (final e in amounts.entries) {
      final sample = samples[e.key]!;
      TrackedCardRef? ref;
      for (final c in cards) {
        if (c.userCardId == sample.userCardId) {
          ref = c;
          break;
        }
      }
      final last4 = sample.cardLast4;
      list.add(CardSpend(
        cardLast4: last4,
        userCardId: ref?.userCardId,
        label: ref?.label ?? (last4 == null ? sample.bankName : '${sample.bankName} •• $last4'),
        bankName: sample.bankName,
        amount: e.value,
        count: counts[e.key] ?? 0,
        share: net > 0 ? (e.value / net).clamp(0.0, 1.0) : 0,
        latestAvailableLimit: latestLimit[e.key]?.availableLimit,
      ));
    }
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  List<MerchantSpend> _topMerchants(List<CardTransaction> txns) {
    final amounts = <String, double>{};
    final counts = <String, int>{};
    final categories = <String, SpendCategory>{};
    for (final t in txns) {
      if (t.category == SpendCategory.fees) continue;
      amounts[t.merchantName] = (amounts[t.merchantName] ?? 0) + t.signedSpend;
      if (t.type == TransactionType.debit) counts[t.merchantName] = (counts[t.merchantName] ?? 0) + 1;
      categories.putIfAbsent(t.merchantName, () => t.category);
    }
    final list = [
      for (final e in amounts.entries)
        if (e.value > 0)
          MerchantSpend(
            merchantName: e.key,
            category: categories[e.key]!,
            amount: e.value,
            count: counts[e.key] ?? 0,
          ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return list.take(topMerchantCount).toList();
  }

  List<MonthlySpend> _monthlyTrend(List<CardTransaction> inr, DateTime end) {
    final lastMonth = DateTime(end.year, end.month - 1);
    return [
      for (var i = trendMonths - 1; i >= 0; i--)
        () {
          final month = DateTime(lastMonth.year, lastMonth.month - i);
          final next = DateTime(month.year, month.month + 1);
          return MonthlySpend(month: month, amount: _net(inr.where((t) => _inRange(t.occurredAt, month, next))));
        }(),
    ];
  }

  /// Flags debits at least 4× the user's 180-day median ticket (and ≥ ₹10,000).
  List<CardTransaction> _unusual(List<CardTransaction> debits, List<CardTransaction> inr, DateTime now) {
    final baseline = inr
        .where((t) => t.type == TransactionType.debit && t.occurredAt.isAfter(now.subtract(const Duration(days: 180))))
        .map((t) => t.amount)
        .toList()
      ..sort();
    if (baseline.length < 5) return const [];
    final median = baseline[baseline.length ~/ 2];
    final threshold = (median * 4).clamp(10000.0, double.infinity);
    final flagged = debits.where((t) => t.amount >= threshold && t.category != SpendCategory.rent).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return flagged.take(3).toList();
  }
}
