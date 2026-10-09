import 'spend_category.dart';

/// Direction / nature of a card transaction.
enum TransactionType {
  /// Purchase, fee or charge that increases card outstanding.
  debit,

  /// Merchant refund credited back to the card.
  refund,

  /// Reversal of a failed / duplicate authorisation.
  reversal,

  /// Credit card bill payment received by the bank (excluded from spend).
  payment,

  /// Other credits such as cashback or reward conversion (excluded from spend).
  credit;

  /// Resolves a wire name, defaulting to [TransactionType.debit].
  static TransactionType fromName(String? name) {
    for (final t in TransactionType.values) {
      if (t.name == name) return t;
    }
    return TransactionType.debit;
  }

  /// Whether this type contributes to the net spend figure.
  bool get affectsSpend => this == debit || this == refund || this == reversal;
}

/// How the transaction was captured.
enum TransactionSource {
  sms,
  pastedSms,
  manual,
  server;

  /// Resolves a wire name, defaulting to [TransactionSource.manual].
  static TransactionSource fromName(String? name) {
    for (final s in TransactionSource.values) {
      if (s.name == name) return s;
    }
    return TransactionSource.manual;
  }
}

/// Payment rail used on the card.
enum TransactionChannel {
  card,
  upi,
  unknown;

  /// Resolves a wire name, defaulting to [TransactionChannel.unknown].
  static TransactionChannel fromName(String? name) {
    for (final c in TransactionChannel.values) {
      if (c.name == name) return c;
    }
    return TransactionChannel.unknown;
  }
}

/// Immutable, structured credit card transaction.
///
/// Zero-knowledge: holds only the last 4 digits of the card and parsed
/// fields. The raw SMS body is never stored on this entity.
class CardTransaction {
  /// Stable dedupe hash (SHA-256 prefix). Doubles as the primary key.
  final String id;
  final double amount;

  /// ISO-4217 currency code (e.g. INR, USD).
  final String currency;
  final TransactionType type;
  final DateTime occurredAt;

  /// Registry code of the issuing bank (e.g. HDFC, ICICI, UNKNOWN).
  final String bankCode;
  final String bankName;
  final String? cardLast4;

  /// Wallet card id matched by last 4 digits (null when no saved card matches).
  final int? userCardId;

  /// Merchant text as it appeared in the alert, trimmed and capped.
  final String merchantRaw;

  /// Normalised display merchant name.
  final String merchantName;
  final SpendCategory category;

  /// True when the user manually overrode the category.
  final bool isCategoryOverridden;
  final TransactionChannel channel;

  /// Available credit limit reported in the alert, if any.
  final double? availableLimit;
  final TransactionSource source;

  /// Parser confidence in the range 0..1 (1.0 for manual entries).
  final double confidence;
  final bool isSynced;

  const CardTransaction({
    required this.id,
    required this.amount,
    this.currency = 'INR',
    required this.type,
    required this.occurredAt,
    required this.bankCode,
    required this.bankName,
    this.cardLast4,
    this.userCardId,
    required this.merchantRaw,
    required this.merchantName,
    required this.category,
    this.isCategoryOverridden = false,
    this.channel = TransactionChannel.unknown,
    this.availableLimit,
    required this.source,
    required this.confidence,
    this.isSynced = false,
  });

  /// Confidence below which the UI shows a "Review" badge.
  static const double reviewThreshold = 0.8;

  bool get needsReview => confidence < reviewThreshold;

  bool get isInternational => currency != 'INR';

  /// Signed contribution to net spend: debits add, refunds/reversals subtract,
  /// bill payments and other credits are neutral.
  double get signedSpend {
    switch (type) {
      case TransactionType.debit:
        return amount;
      case TransactionType.refund:
      case TransactionType.reversal:
        return -amount;
      case TransactionType.payment:
      case TransactionType.credit:
        return 0;
    }
  }

  CardTransaction copyWith({
    int? userCardId,
    bool clearUserCardId = false,
    String? merchantName,
    SpendCategory? category,
    bool? isCategoryOverridden,
    bool? isSynced,
  }) {
    return CardTransaction(
      id: id,
      amount: amount,
      currency: currency,
      type: type,
      occurredAt: occurredAt,
      bankCode: bankCode,
      bankName: bankName,
      cardLast4: cardLast4,
      userCardId: clearUserCardId ? null : (userCardId ?? this.userCardId),
      merchantRaw: merchantRaw,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      isCategoryOverridden: isCategoryOverridden ?? this.isCategoryOverridden,
      channel: channel,
      availableLimit: availableLimit,
      source: source,
      confidence: confidence,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
