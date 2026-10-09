import '../entities/bill_notice.dart';
import '../entities/card_transaction.dart';

/// Infers whether parsed statement notices have been paid, using later
/// "payment received" SMS on the same card.
class BillStatusResolver {
  const BillStatusResolver();

  /// Latest relevant bill per card, unpaid / overdue first, then by due date.
  List<BillStatus> resolve(List<BillNotice> bills, List<CardTransaction> transactions, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);

    final latest = <String, BillNotice>{};
    for (final b in bills) {
      final key = '${b.bankCode}|${b.cardLast4 ?? '-'}';
      final existing = latest[key];
      if (existing == null || b.noticedAt.isAfter(existing.noticedAt)) latest[key] = b;
    }

    final statuses = <BillStatus>[];
    for (final bill in latest.values) {
      final due = bill.dueDate;
      if (due != null && due.isBefore(today.subtract(const Duration(days: 7)))) continue;
      if (due == null && clock.difference(bill.noticedAt).inDays > 35) continue;

      final paid = transactions
          .where((t) =>
              t.type == TransactionType.payment &&
              t.cardLast4 == bill.cardLast4 &&
              (bill.bankCode == 'UNKNOWN' || t.bankCode == bill.bankCode) &&
              !t.occurredAt.isBefore(bill.noticedAt.subtract(const Duration(days: 1))))
          .fold<double>(0, (a, t) => a + t.amount);

      final BillPaymentState state;
      final total = bill.totalDue;
      final minimum = bill.minimumDue;
      if ((total != null && (total <= 0 || paid >= total * 0.99))) {
        state = BillPaymentState.paid;
      } else if (minimum != null && paid >= minimum) {
        state = BillPaymentState.minimumPaid;
      } else if (due != null && due.isBefore(today)) {
        state = BillPaymentState.overdue;
      } else {
        state = BillPaymentState.unpaid;
      }

      statuses.add(BillStatus(
        notice: bill,
        state: state,
        paidAmount: paid,
        daysUntilDue: due?.difference(today).inDays,
      ));
    }

    int rank(BillPaymentState s) => switch (s) {
          BillPaymentState.overdue => 0,
          BillPaymentState.unpaid => 1,
          BillPaymentState.minimumPaid => 2,
          BillPaymentState.paid => 3,
        };
    statuses.sort((a, b) {
      final r = rank(a.state).compareTo(rank(b.state));
      if (r != 0) return r;
      return (a.daysUntilDue ?? 999).compareTo(b.daysUntilDue ?? 999);
    });
    return statuses;
  }
}
