import '../../domain/entities/sms_parse_result.dart';

/// User-facing explanation of why an SMS was filtered out.
extension SmsRejectReasonLabel on SmsRejectReason {
  String get label => switch (this) {
        SmsRejectReason.unknownSender => 'Sender is not a recognised bank',
        SmsRejectReason.personalNumber => 'Sent from a phone number (possible spoof)',
        SmsRejectReason.promotional => 'Promotional message',
        SmsRejectReason.otp => 'OTP / verification code — never stored',
        SmsRejectReason.mandateNotice => 'Upcoming e-mandate / auto-pay notice',
        SmsRejectReason.declined => 'Declined or failed transaction',
        SmsRejectReason.notCreditCard => 'Debit card or bank account alert',
        SmsRejectReason.noAmount => 'No amount found',
        SmsRejectReason.informational => 'Informational message, not a transaction',
        SmsRejectReason.lowConfidence => 'Could not parse with enough confidence',
      };

  String get shortLabel => switch (this) {
        SmsRejectReason.unknownSender => 'Unknown sender',
        SmsRejectReason.personalNumber => 'Phone sender',
        SmsRejectReason.promotional => 'Promos',
        SmsRejectReason.otp => 'OTPs',
        SmsRejectReason.mandateNotice => 'Mandate notices',
        SmsRejectReason.declined => 'Declined',
        SmsRejectReason.notCreditCard => 'Debit/account',
        SmsRejectReason.noAmount => 'No amount',
        SmsRejectReason.informational => 'Info',
        SmsRejectReason.lowConfidence => 'Low confidence',
      };
}
