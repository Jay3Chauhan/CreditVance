import 'card_transaction.dart';
import 'spend_category.dart';

/// Coarse type filter for the transaction list.
enum TransactionTypeFilter {
  all('All'),
  spends('Spends'),
  refunds('Refunds'),
  payments('Payments'),
  needsReview('Review');

  const TransactionTypeFilter(this.label);
  final String label;
}

/// Immutable filter applied to the transaction list.
class TransactionFilter {
  final TransactionTypeFilter type;
  final SpendCategory? category;

  /// Card last 4 digits; null means all cards.
  final String? cardLast4;
  final String query;

  const TransactionFilter({
    this.type = TransactionTypeFilter.all,
    this.category,
    this.cardLast4,
    this.query = '',
  });

  static const TransactionFilter none = TransactionFilter();

  bool get isActive =>
      type != TransactionTypeFilter.all || category != null || cardLast4 != null || query.isNotEmpty;

  TransactionFilter copyWith({
    TransactionTypeFilter? type,
    SpendCategory? category,
    bool clearCategory = false,
    String? cardLast4,
    bool clearCard = false,
    String? query,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      category: clearCategory ? null : (category ?? this.category),
      cardLast4: clearCard ? null : (cardLast4 ?? this.cardLast4),
      query: query ?? this.query,
    );
  }

  /// Whether [txn] passes every active criterion.
  bool matches(CardTransaction txn) {
    switch (type) {
      case TransactionTypeFilter.all:
        break;
      case TransactionTypeFilter.spends:
        if (txn.type != TransactionType.debit) return false;
      case TransactionTypeFilter.refunds:
        if (txn.type != TransactionType.refund && txn.type != TransactionType.reversal) return false;
      case TransactionTypeFilter.payments:
        if (txn.type != TransactionType.payment && txn.type != TransactionType.credit) return false;
      case TransactionTypeFilter.needsReview:
        if (!txn.needsReview) return false;
    }
    if (category != null && txn.category != category) return false;
    if (cardLast4 != null && txn.cardLast4 != cardLast4) return false;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      if (!txn.merchantName.toLowerCase().contains(q) &&
          !txn.merchantRaw.toLowerCase().contains(q) &&
          !txn.bankName.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }
}
