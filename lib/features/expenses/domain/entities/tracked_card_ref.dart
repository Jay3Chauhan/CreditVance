/// Minimal, non-sensitive reference to a saved wallet card used for
/// matching parsed transactions by last 4 digits.
class TrackedCardRef {
  final int userCardId;
  final String last4;
  final String label;
  final String bankName;

  /// Catalog product name (e.g. "HDFC Infinia Metal Edition"), used to look up
  /// milestone rules when the backend is unreachable.
  final String cardName;
  final double annualFee;

  const TrackedCardRef({
    required this.userCardId,
    required this.last4,
    required this.label,
    required this.bankName,
    this.cardName = '',
    this.annualFee = 0,
  });
}
