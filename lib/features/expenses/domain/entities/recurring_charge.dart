import 'spend_category.dart';

/// Detected billing cadence of a recurring charge.
enum RecurringCadence {
  weekly('Weekly', 7),
  monthly('Monthly', 30),
  quarterly('Quarterly', 91),
  yearly('Yearly', 365);

  const RecurringCadence(this.label, this.approxDays);
  final String label;
  final int approxDays;
}

/// A subscription or repeating charge detected from transaction history.
class RecurringCharge {
  final String merchantName;
  final SpendCategory category;
  final String? cardLast4;
  final RecurringCadence cadence;
  final double averageAmount;
  final double lastAmount;
  final int occurrences;
  final DateTime lastChargedAt;
  final DateTime nextExpectedAt;

  const RecurringCharge({
    required this.merchantName,
    required this.category,
    required this.cardLast4,
    required this.cadence,
    required this.averageAmount,
    required this.lastAmount,
    required this.occurrences,
    required this.lastChargedAt,
    required this.nextExpectedAt,
  });

  /// Normalised yearly cost at the average amount.
  double get annualisedCost => averageAmount * (365 / cadence.approxDays);

  /// True when the latest charge is noticeably higher than the average (price hike).
  bool get hasPriceIncrease => lastAmount > averageAmount * 1.1;
}
