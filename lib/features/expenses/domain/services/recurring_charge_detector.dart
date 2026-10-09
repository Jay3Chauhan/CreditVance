import '../entities/card_transaction.dart';
import '../entities/recurring_charge.dart';
import '../entities/spend_category.dart';

/// Detects subscriptions and other repeating charges from debit history.
///
/// Heuristic: same normalised merchant on the same card, intervals that fit a
/// weekly / monthly / quarterly / yearly cadence, and amounts within ±25% of
/// the median. Stale series (no charge for 2× the cadence) are dropped.
class RecurringChargeDetector {
  const RecurringChargeDetector();

  static const Set<String> _ignoredMerchants = {'Unknown Merchant', 'UPI Merchant', 'Card Credit'};

  /// Returns active recurring charges sorted by next expected date.
  List<RecurringCharge> detect(List<CardTransaction> transactions, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final groups = <String, List<CardTransaction>>{};
    for (final t in transactions) {
      if (t.type != TransactionType.debit) continue;
      if (t.category == SpendCategory.fees || _ignoredMerchants.contains(t.merchantName)) continue;
      final key = '${t.merchantName.toLowerCase()}|${t.cardLast4 ?? ''}|${t.currency}';
      groups.putIfAbsent(key, () => []).add(t);
    }

    final result = <RecurringCharge>[];
    for (final series in groups.values) {
      if (series.length < 2) continue;
      series.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      final charge = _evaluate(series, clock);
      if (charge != null) result.add(charge);
    }
    result.sort((a, b) => a.nextExpectedAt.compareTo(b.nextExpectedAt));
    return result;
  }

  static RecurringCadence? _cadenceFor(double days) {
    if (days >= 6 && days <= 8) return RecurringCadence.weekly;
    if (days >= 26 && days <= 35) return RecurringCadence.monthly;
    if (days >= 84 && days <= 98) return RecurringCadence.quarterly;
    if (days >= 350 && days <= 380) return RecurringCadence.yearly;
    return null;
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  RecurringCharge? _evaluate(List<CardTransaction> series, DateTime now) {
    final intervals = <double>[
      for (var i = 1; i < series.length; i++)
        series[i].occurredAt.difference(series[i - 1].occurredAt).inHours / 24.0,
    ];
    final cadence = _cadenceFor(_median(intervals));
    if (cadence == null) return null;

    final isSubscription = series.first.category == SpendCategory.subscriptions;
    final minOccurrences =
        (cadence == RecurringCadence.yearly || cadence == RecurringCadence.quarterly || isSubscription) ? 2 : 3;
    if (series.length < minOccurrences) return null;

    final fitting = intervals.where((d) => _cadenceFor(d) == cadence).length;
    if (fitting / intervals.length < 0.6) return null;

    final amounts = series.map((t) => t.amount).toList();
    final medianAmount = _median(amounts);
    final consistent = amounts.where((a) => (a - medianAmount).abs() <= medianAmount * 0.25).length;
    if (consistent / amounts.length < 0.75) return null;

    final last = series.last;
    if (now.difference(last.occurredAt).inDays > cadence.approxDays * 2) return null;

    final next = switch (cadence) {
      RecurringCadence.monthly =>
        DateTime(last.occurredAt.year, last.occurredAt.month + 1, last.occurredAt.day),
      RecurringCadence.quarterly =>
        DateTime(last.occurredAt.year, last.occurredAt.month + 3, last.occurredAt.day),
      RecurringCadence.yearly => DateTime(last.occurredAt.year + 1, last.occurredAt.month, last.occurredAt.day),
      RecurringCadence.weekly => last.occurredAt.add(const Duration(days: 7)),
    };

    return RecurringCharge(
      merchantName: last.merchantName,
      category: last.category,
      cardLast4: last.cardLast4,
      cadence: cadence,
      averageAmount: amounts.reduce((a, b) => a + b) / amounts.length,
      lastAmount: last.amount,
      occurrences: series.length,
      lastChargedAt: last.occurredAt,
      nextExpectedAt: next,
    );
  }
}
