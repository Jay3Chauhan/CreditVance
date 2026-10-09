import 'package:credvert/features/expenses/domain/entities/bill_notice.dart';
import 'package:credvert/features/expenses/domain/entities/card_milestone.dart';
import 'package:credvert/features/expenses/domain/entities/card_transaction.dart';
import 'package:credvert/features/expenses/domain/entities/recurring_charge.dart';
import 'package:credvert/features/expenses/domain/entities/spend_analytics.dart';
import 'package:credvert/features/expenses/domain/entities/spend_category.dart';
import 'package:credvert/features/expenses/domain/entities/tracked_card_ref.dart';
import 'package:credvert/features/expenses/domain/services/bill_status_resolver.dart';
import 'package:credvert/features/expenses/domain/services/card_matcher.dart';
import 'package:credvert/features/expenses/domain/services/milestone_calculator.dart';
import 'package:credvert/features/expenses/domain/services/recurring_charge_detector.dart';
import 'package:credvert/features/expenses/domain/services/spend_analytics_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

CardTransaction txn(
  String id,
  double amount,
  DateTime at, {
  TransactionType type = TransactionType.debit,
  String merchant = 'Amazon',
  SpendCategory category = SpendCategory.shopping,
  String last4 = '1234',
  int? userCardId = 101,
  String currency = 'INR',
}) {
  return CardTransaction(
    id: id,
    amount: amount,
    currency: currency,
    type: type,
    occurredAt: at,
    bankCode: 'HDFC',
    bankName: 'HDFC Bank',
    cardLast4: last4,
    userCardId: userCardId,
    merchantRaw: merchant.toUpperCase(),
    merchantName: merchant,
    category: category,
    source: TransactionSource.sms,
    confidence: 0.95,
  );
}

void main() {
  final now = DateTime(2025, 5, 20, 12);

  group('SpendAnalyticsCalculator', () {
    const calc = SpendAnalyticsCalculator();

    test('net spend subtracts refunds, ignores payments and forex, splits by category and card', () {
      final txns = [
        txn('a', 1000, DateTime(2025, 5, 2)),
        txn('b', 500, DateTime(2025, 5, 3), merchant: 'Swiggy', category: SpendCategory.dining),
        txn('c', 200, DateTime(2025, 5, 4), type: TransactionType.refund),
        txn('d', 15000, DateTime(2025, 5, 5), type: TransactionType.payment, merchant: 'Card Bill Payment'),
        txn('e', 25, DateTime(2025, 5, 6), currency: 'USD', merchant: 'Netflix'),
        txn('f', 700, DateTime(2025, 5, 7), last4: '9999', userCardId: null),
        txn('g', 400, DateTime(2025, 4, 10)), // previous month
      ];
      final a = calc.compute(
        transactions: txns,
        period: AnalyticsPeriod.thisMonth,
        cards: const [TrackedCardRef(userCardId: 101, last4: '1234', label: 'Primary Infinia', bankName: 'HDFC Bank')],
        now: now,
      );

      expect(a.grossSpend, 2200);
      expect(a.refunds, 200);
      expect(a.netSpend, 2000);
      expect(a.debitCount, 3);
      expect(a.internationalCount, 1);
      expect(a.previousPeriodSpend, 400);
      expect(a.changeVsPrevious, closeTo(4.0, 0.001));
      expect(a.byCategory.first.category, SpendCategory.shopping);
      expect(a.byCategory.first.amount, 1500);
      expect(a.byCard.first.label, 'Primary Infinia');
      expect(a.byCard.last.isUnlinked, isTrue);
      expect(a.monthlyTrend.length, 6);
      expect(a.monthlyTrend.last.amount, 2000);
    });

    test('ranges are calendar aligned', () {
      final (start, end) = SpendAnalyticsCalculator.rangeFor(AnalyticsPeriod.last3Months, now);
      expect(start, DateTime(2025, 3));
      expect(end, DateTime(2025, 6));
      final (prevStart, prevEnd) = SpendAnalyticsCalculator.previousRangeFor(AnalyticsPeriod.last3Months, now);
      expect(prevStart, DateTime(2024, 12));
      expect(prevEnd, DateTime(2025, 3));
    });
  });

  group('RecurringChargeDetector', () {
    const detector = RecurringChargeDetector();

    test('detects a monthly subscription and predicts the next charge', () {
      final txns = [
        txn('n1', 649, DateTime(2025, 2, 5), merchant: 'Netflix', category: SpendCategory.subscriptions),
        txn('n2', 649, DateTime(2025, 3, 5), merchant: 'Netflix', category: SpendCategory.subscriptions),
        txn('n3', 649, DateTime(2025, 4, 5), merchant: 'Netflix', category: SpendCategory.subscriptions),
        txn('n4', 799, DateTime(2025, 5, 5), merchant: 'Netflix', category: SpendCategory.subscriptions),
        txn('x1', 1200, DateTime(2025, 5, 1), merchant: 'Amazon'),
        txn('x2', 300, DateTime(2025, 5, 9), merchant: 'Amazon'),
      ];
      final result = detector.detect(txns, now: now);
      expect(result.length, 1);
      expect(result.first.merchantName, 'Netflix');
      expect(result.first.cadence, RecurringCadence.monthly);
      expect(result.first.nextExpectedAt, DateTime(2025, 6, 5));
      expect(result.first.hasPriceIncrease, isTrue);
    });

    test('ignores stale series', () {
      final txns = [
        txn('s1', 199, DateTime(2024, 9, 1), merchant: 'Spotify', category: SpendCategory.subscriptions),
        txn('s2', 199, DateTime(2024, 10, 1), merchant: 'Spotify', category: SpendCategory.subscriptions),
      ];
      expect(detector.detect(txns, now: now), isEmpty);
    });
  });

  group('MilestoneCalculator', () {
    const calc = MilestoneCalculator();

    test('card-year window, progress and projection', () {
      const milestone = CardMilestone(
        id: 'm1',
        userCardId: 101,
        title: 'Annual fee waiver',
        rewardDescription: 'Renewal fee waived',
        type: MilestoneType.feeWaiver,
        period: MilestonePeriod.cardYear,
        targetSpend: 400000,
        anniversaryMonth: 4,
      );
      final txns = [
        txn('a', 50000, DateTime(2025, 4, 10)),
        txn('b', 50000, DateTime(2025, 5, 10)),
        txn('c', 90000, DateTime(2025, 3, 10)), // previous card year
        txn('d', 10000, DateTime(2025, 5, 11), userCardId: 202), // other card
      ];
      final p = calc.compute(milestone: milestone, transactions: txns, cardLabel: 'Regalia', now: now);
      expect(p.windowStart, DateTime(2025, 4));
      expect(p.windowEnd, DateTime(2026, 4));
      expect(p.spent, 100000);
      expect(p.progress, 0.25);
      expect(p.isAchieved, isFalse);
      expect(p.projectedCompletion, isNotNull);
      expect(p.isAtRisk, isFalse);
    });
  });

  group('BillStatusResolver', () {
    const resolver = BillStatusResolver();

    test('marks a bill paid once a matching payment SMS arrives', () {
      final bill = BillNotice(
        id: 'b1',
        bankCode: 'HDFC',
        bankName: 'HDFC Bank',
        cardLast4: '1234',
        totalDue: 12000,
        minimumDue: 600,
        dueDate: DateTime(2025, 5, 25),
        noticedAt: DateTime(2025, 5, 5),
      );
      final unpaid = resolver.resolve([bill], const [], now: now);
      expect(unpaid.single.state, BillPaymentState.unpaid);
      expect(unpaid.single.daysUntilDue, 5);

      final paid = resolver.resolve(
        [bill],
        [txn('p', 12000, DateTime(2025, 5, 18), type: TransactionType.payment)],
        now: now,
      );
      expect(paid.single.state, BillPaymentState.paid);

      final overdue = resolver.resolve([bill], const [], now: DateTime(2025, 5, 27));
      expect(overdue.single.state, BillPaymentState.overdue);
    });
  });

  group('CardMatcher', () {
    test('matches by last 4 and breaks ties by issuer', () {
      const matcher = CardMatcher();
      const cards = [
        TrackedCardRef(userCardId: 1, last4: '1234', label: 'A', bankName: 'HDFC Bank'),
        TrackedCardRef(userCardId: 2, last4: '1234', label: 'B', bankName: 'ICICI Bank'),
        TrackedCardRef(userCardId: 3, last4: '9999', label: 'C', bankName: 'SBI Card'),
      ];
      expect(matcher.match(last4: '9999', bankName: 'SBI Card', cards: cards), 3);
      expect(matcher.match(last4: '1234', bankName: 'ICICI Bank', cards: cards), 2);
      expect(matcher.match(last4: '0000', bankName: 'HDFC Bank', cards: cards), isNull);
      expect(matcher.match(last4: null, bankName: 'HDFC Bank', cards: cards), isNull);
    });
  });
}
