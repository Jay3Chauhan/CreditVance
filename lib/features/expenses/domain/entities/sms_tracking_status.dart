import 'sms_parse_result.dart';

/// User decision recorded by the prominent-disclosure consent screen.
enum SmsConsentStatus {
  notAsked,
  granted,
  declined,

  /// User paused tracking / withdrew consent after granting it.
  withdrawn;

  /// Resolves a wire name, defaulting to [SmsConsentStatus.notAsked].
  static SmsConsentStatus fromName(String? name) {
    for (final s in SmsConsentStatus.values) {
      if (s.name == name) return s;
    }
    return SmsConsentStatus.notAsked;
  }
}

/// Auditable consent record (DPDP: purpose-specific, versioned, timestamped).
class SmsConsent {
  /// Bump when the disclosure text or data purposes change; forces re-consent.
  static const String currentVersion = 'sms-v1';

  final SmsConsentStatus status;
  final String version;
  final DateTime? decidedAt;

  /// Whether the latest decision has been recorded on the backend.
  final bool isSyncedToServer;

  const SmsConsent({
    required this.status,
    this.version = currentVersion,
    this.decidedAt,
    this.isSyncedToServer = false,
  });

  static const SmsConsent initial = SmsConsent(status: SmsConsentStatus.notAsked);

  bool get isGranted => status == SmsConsentStatus.granted && version == currentVersion;

  SmsConsent copyWith({SmsConsentStatus? status, DateTime? decidedAt, bool? isSyncedToServer}) {
    return SmsConsent(
      status: status ?? this.status,
      version: currentVersion,
      decidedAt: decidedAt ?? this.decidedAt,
      isSyncedToServer: isSyncedToServer ?? this.isSyncedToServer,
    );
  }
}

/// Android runtime permission state for READ_SMS / RECEIVE_SMS.
enum SmsPermissionStatus {
  granted,
  denied,

  /// "Don't ask again" — only the system settings page can re-enable it.
  permanentlyDenied,

  /// Platform cannot read SMS at all (iOS, web, desktop).
  unsupported,
}

/// Backend sync health surfaced in the UI.
enum ExpenseSyncStatus {
  idle,
  syncing,
  synced,
  offline,

  /// 401 — user must sign in before parsed data can be backed up.
  signedOut,

  /// 404 — backend expense endpoints not deployed; app runs local-only.
  unavailable,
  serverError,
}

/// Summary of one inbox scan pass.
class SmsScanReport {
  final int scanned;
  final int newTransactions;
  final int newBills;
  final Map<SmsRejectReason, int> rejected;

  const SmsScanReport({
    required this.scanned,
    required this.newTransactions,
    required this.newBills,
    required this.rejected,
  });

  static const SmsScanReport none =
      SmsScanReport(scanned: 0, newTransactions: 0, newBills: 0, rejected: {});

  int get rejectedCount => rejected.values.fold(0, (a, b) => a + b);
}

/// Summary of one backend sync pass.
class ExpenseSyncReport {
  final ExpenseSyncStatus status;
  final int uploaded;
  final int pending;
  final String? message;

  const ExpenseSyncReport({
    required this.status,
    required this.uploaded,
    required this.pending,
    this.message,
  });
}
