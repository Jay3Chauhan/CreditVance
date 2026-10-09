/// Credit card statement / bill-due notice parsed from a bank SMS.
class BillNotice {
  /// Dedupe hash of bank + last4 + due date.
  final String id;
  final String bankCode;
  final String bankName;
  final String? cardLast4;
  final int? userCardId;
  final double? totalDue;
  final double? minimumDue;
  final DateTime? dueDate;

  /// When the notice SMS was received (proxy for statement date).
  final DateTime noticedAt;

  const BillNotice({
    required this.id,
    required this.bankCode,
    required this.bankName,
    this.cardLast4,
    this.userCardId,
    this.totalDue,
    this.minimumDue,
    this.dueDate,
    required this.noticedAt,
  });

  BillNotice copyWith({int? userCardId}) {
    return BillNotice(
      id: id,
      bankCode: bankCode,
      bankName: bankName,
      cardLast4: cardLast4,
      userCardId: userCardId ?? this.userCardId,
      totalDue: totalDue,
      minimumDue: minimumDue,
      dueDate: dueDate,
      noticedAt: noticedAt,
    );
  }
}

/// Payment state of a bill, inferred from later payment SMS.
enum BillPaymentState { unpaid, minimumPaid, paid, overdue }

/// A bill notice enriched with inferred payment state.
class BillStatus {
  final BillNotice notice;
  final BillPaymentState state;
  final double paidAmount;

  /// Days until due (negative when overdue); null when due date unknown.
  final int? daysUntilDue;

  const BillStatus({
    required this.notice,
    required this.state,
    required this.paidAmount,
    this.daysUntilDue,
  });
}
