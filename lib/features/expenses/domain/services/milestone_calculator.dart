import '../entities/card_milestone.dart';
import '../entities/card_transaction.dart';

/// Computes progress towards card spend milestones from parsed transactions.
class MilestoneCalculator {
  const MilestoneCalculator();

  /// Half-open accumulation window `[start, end)` containing [now].
  static (DateTime, DateTime) windowFor(CardMilestone milestone, DateTime now) {
    switch (milestone.period) {
      case MilestonePeriod.calendarMonth:
        return (DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
      case MilestonePeriod.calendarQuarter:
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return (DateTime(now.year, startMonth), DateTime(now.year, startMonth + 3));
      case MilestonePeriod.calendarYear:
        return (DateTime(now.year), DateTime(now.year + 1));
      case MilestonePeriod.cardYear:
        final a = milestone.anniversaryMonth.clamp(1, 12);
        final startYear = now.month >= a ? now.year : now.year - 1;
        return (DateTime(startYear, a), DateTime(startYear + 1, a));
    }
  }

  /// Progress for one milestone; only INR spend on the matched card counts.
  MilestoneProgress compute({
    required CardMilestone milestone,
    required List<CardTransaction> transactions,
    required String cardLabel,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final (start, end) = windowFor(milestone, clock);
    final spent = transactions
        .where((t) =>
            t.userCardId == milestone.userCardId &&
            !t.isInternational &&
            !t.occurredAt.isBefore(start) &&
            t.occurredAt.isBefore(end))
        .fold<double>(0, (a, t) => a + t.signedSpend)
        .clamp(0.0, double.infinity);

    DateTime? projected;
    if (spent < milestone.targetSpend && spent > 0) {
      final elapsedDays = clock.difference(start).inHours / 24.0;
      final perDay = spent / (elapsedDays < 1 ? 1 : elapsedDays);
      final daysNeeded = (milestone.targetSpend - spent) / perDay;
      if (daysNeeded < 3650) projected = clock.add(Duration(hours: (daysNeeded * 24).round()));
    }

    return MilestoneProgress(
      milestone: milestone,
      cardLabel: cardLabel,
      spent: spent,
      windowStart: start,
      windowEnd: end,
      projectedCompletion: projected,
    );
  }
}
