import '../../domain/entities/sms_tracking_status.dart';

/// DTO for the SMS tracking [SmsConsent] record.
class SmsConsentModel extends SmsConsent {
  const SmsConsentModel({
    required super.status,
    super.version,
    super.decidedAt,
    super.isSyncedToServer,
  });

  factory SmsConsentModel.fromEntity(SmsConsent c) => SmsConsentModel(
        status: c.status,
        version: c.version,
        decidedAt: c.decidedAt,
        isSyncedToServer: c.isSyncedToServer,
      );

  factory SmsConsentModel.fromJson(Map<String, dynamic> json) {
    final decided = json['decided_at'] as String?;
    return SmsConsentModel(
      status: SmsConsentStatus.fromName(json['status'] as String?),
      version: json['version'] as String? ?? SmsConsent.currentVersion,
      decidedAt: decided == null ? null : DateTime.parse(decided).toLocal(),
      isSyncedToServer: json['is_synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'version': version,
        'decided_at': decidedAt?.toIso8601String(),
        'is_synced': isSyncedToServer,
      };

  /// `PUT /expenses/consent` payload (DPDP consent artefact).
  Map<String, dynamic> toSyncJson() => {
        'purpose': 'sms_card_expense_tracking',
        'status': status.name,
        'notice_version': version,
        'decided_at': decidedAt?.toUtc().toIso8601String(),
        'platform': 'android',
      };
}
