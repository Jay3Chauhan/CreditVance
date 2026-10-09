/// Where an SMS body entered the parser from.
enum SmsOrigin {
  /// Read from the Android SMS inbox or the live SMS broadcast.
  inbox,

  /// Pasted by the user (iOS fallback / manual import). Sender may be empty.
  pasted,
}

/// Transient SMS envelope handed to the on-device parser.
///
/// Never persisted and never serialised to the backend.
class RawSms {
  final String sender;
  final String body;
  final DateTime receivedAt;
  final SmsOrigin origin;

  const RawSms({
    required this.sender,
    required this.body,
    required this.receivedAt,
    this.origin = SmsOrigin.inbox,
  });
}
