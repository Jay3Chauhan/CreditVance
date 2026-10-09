import 'bill_notice.dart';
import 'card_transaction.dart';

/// Why an SMS was not turned into a transaction.
enum SmsRejectReason {
  unknownSender,
  personalNumber,
  promotional,
  otp,
  mandateNotice,
  declined,
  notCreditCard,
  noAmount,
  informational,
  lowConfidence,
}

/// Result of running the on-device SMS parser over one message.
sealed class SmsParseOutcome {
  const SmsParseOutcome();
}

/// The SMS described a completed card transaction.
class ParsedTransaction extends SmsParseOutcome {
  final CardTransaction transaction;
  const ParsedTransaction(this.transaction);
}

/// The SMS was a statement / payment-due notice.
class ParsedBillNotice extends SmsParseOutcome {
  final BillNotice notice;
  const ParsedBillNotice(this.notice);
}

/// The SMS was filtered out.
class RejectedSms extends SmsParseOutcome {
  final SmsRejectReason reason;
  const RejectedSms(this.reason);
}
