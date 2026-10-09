import '../../domain/entities/bill_notice.dart';

/// DTO for [BillNotice] — local cache JSON and backend sync payload.
class BillNoticeModel extends BillNotice {
  const BillNoticeModel({
    required super.id,
    required super.bankCode,
    required super.bankName,
    super.cardLast4,
    super.userCardId,
    super.totalDue,
    super.minimumDue,
    super.dueDate,
    required super.noticedAt,
  });

  factory BillNoticeModel.fromEntity(BillNotice b) {
    return BillNoticeModel(
      id: b.id,
      bankCode: b.bankCode,
      bankName: b.bankName,
      cardLast4: b.cardLast4,
      userCardId: b.userCardId,
      totalDue: b.totalDue,
      minimumDue: b.minimumDue,
      dueDate: b.dueDate,
      noticedAt: b.noticedAt,
    );
  }

  factory BillNoticeModel.fromJson(Map<String, dynamic> json) {
    final due = json['due_date'] as String?;
    return BillNoticeModel(
      id: (json['dedupe_hash'] ?? json['id']) as String,
      bankCode: json['bank_code'] as String? ?? 'UNKNOWN',
      bankName: json['bank_name'] as String? ?? 'Card',
      cardLast4: json['card_last4'] as String?,
      userCardId: json['user_card_id'] as int?,
      totalDue: (json['total_due'] as num?)?.toDouble(),
      minimumDue: (json['minimum_due'] as num?)?.toDouble(),
      dueDate: due == null ? null : DateTime.parse(due),
      noticedAt: DateTime.parse(json['noticed_at'] as String).toLocal(),
    );
  }

  static String? _date(DateTime? d) =>
      d == null ? null : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'bank_code': bankCode,
        'bank_name': bankName,
        'card_last4': cardLast4,
        'user_card_id': userCardId,
        'total_due': totalDue,
        'minimum_due': minimumDue,
        'due_date': _date(dueDate),
        'noticed_at': noticedAt.toIso8601String(),
      };

  /// Backend ingestion payload.
  Map<String, dynamic> toSyncJson() => {
        'dedupe_hash': id,
        'bank_code': bankCode,
        'card_last4': cardLast4,
        'user_card_id': userCardId,
        'total_due': totalDue,
        'minimum_due': minimumDue,
        'due_date': _date(dueDate),
        'noticed_at': noticedAt.toUtc().toIso8601String(),
      };
}
