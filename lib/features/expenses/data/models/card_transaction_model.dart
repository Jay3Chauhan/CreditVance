import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/spend_category.dart';

/// DTO for [CardTransaction] — local cache JSON and backend sync payload.
class CardTransactionModel extends CardTransaction {
  const CardTransactionModel({
    required super.id,
    required super.amount,
    super.currency,
    required super.type,
    required super.occurredAt,
    required super.bankCode,
    required super.bankName,
    super.cardLast4,
    super.userCardId,
    required super.merchantRaw,
    required super.merchantName,
    required super.category,
    super.isCategoryOverridden,
    super.channel,
    super.availableLimit,
    required super.source,
    required super.confidence,
    super.isSynced,
  });

  factory CardTransactionModel.fromEntity(CardTransaction t) {
    return CardTransactionModel(
      id: t.id,
      amount: t.amount,
      currency: t.currency,
      type: t.type,
      occurredAt: t.occurredAt,
      bankCode: t.bankCode,
      bankName: t.bankName,
      cardLast4: t.cardLast4,
      userCardId: t.userCardId,
      merchantRaw: t.merchantRaw,
      merchantName: t.merchantName,
      category: t.category,
      isCategoryOverridden: t.isCategoryOverridden,
      channel: t.channel,
      availableLimit: t.availableLimit,
      source: t.source,
      confidence: t.confidence,
      isSynced: t.isSynced,
    );
  }

  /// Parses both the local cache shape and the backend `GET /expenses/transactions` shape.
  factory CardTransactionModel.fromJson(Map<String, dynamic> json) {
    return CardTransactionModel(
      id: (json['dedupe_hash'] ?? json['id']) as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      type: TransactionType.fromName(json['type'] as String?),
      occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
      bankCode: json['bank_code'] as String? ?? 'UNKNOWN',
      bankName: json['bank_name'] as String? ?? 'Card',
      cardLast4: json['card_last4'] as String?,
      userCardId: json['user_card_id'] as int?,
      merchantRaw: json['merchant_raw'] as String? ?? '',
      merchantName: json['merchant_name'] as String? ?? 'Unknown Merchant',
      category: SpendCategory.fromSlug(json['category'] as String?),
      isCategoryOverridden: json['category_overridden'] as bool? ?? false,
      channel: TransactionChannel.fromName(json['channel'] as String?),
      availableLimit: (json['available_limit'] as num?)?.toDouble(),
      source: TransactionSource.fromName(json['source'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isSynced: json['is_synced'] as bool? ?? false,
    );
  }

  /// Full local-cache representation.
  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'type': type.name,
        'occurred_at': occurredAt.toIso8601String(),
        'bank_code': bankCode,
        'bank_name': bankName,
        'card_last4': cardLast4,
        'user_card_id': userCardId,
        'merchant_raw': merchantRaw,
        'merchant_name': merchantName,
        'category': category.slug,
        'category_overridden': isCategoryOverridden,
        'channel': channel.name,
        'available_limit': availableLimit,
        'source': source.name,
        'confidence': confidence,
        'is_synced': isSynced,
      };

  /// Backend ingestion payload — structured fields only.
  ///
  /// Never includes the SMS body, full PAN, CVV or expiry. Unrecognised UPI
  /// handles (which may identify a person) are withheld from `merchant_raw`.
  Map<String, dynamic> toSyncJson() {
    final isPersonalVpa = merchantRaw.contains('@') && merchantName == 'UPI Merchant';
    return {
      'dedupe_hash': id,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'bank_code': bankCode,
      'card_last4': cardLast4,
      'user_card_id': userCardId,
      'merchant_raw': isPersonalVpa ? null : merchantRaw,
      'merchant_name': merchantName,
      'category': category.slug,
      'category_overridden': isCategoryOverridden,
      'channel': channel.name,
      'available_limit': availableLimit,
      'source': source.name,
      'confidence': confidence,
    };
  }
}
