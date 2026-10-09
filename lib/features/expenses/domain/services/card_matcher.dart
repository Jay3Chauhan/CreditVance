import '../entities/tracked_card_ref.dart';

/// Matches parsed alerts to saved wallet cards using only the last 4 digits
/// (plus the issuer name to break ties). Never needs the full PAN.
class CardMatcher {
  const CardMatcher();

  /// Returns the matched wallet card id, or null when no saved card fits.
  int? match({required String? last4, required String bankName, required List<TrackedCardRef> cards}) {
    if (last4 == null || last4.isEmpty) return null;
    final candidates = cards.where((c) => c.last4 == last4).toList();
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first.userCardId;

    final issuer = bankName.toLowerCase().split(' ').first;
    for (final c in candidates) {
      if (c.bankName.toLowerCase().contains(issuer)) return c.userCardId;
    }
    return candidates.first.userCardId;
  }
}
