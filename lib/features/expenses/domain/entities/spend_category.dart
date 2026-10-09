/// Spend category taxonomy shared with the backend (`category` slug field).
/// Visual mapping (icon/colour) lives in the presentation layer.
enum SpendCategory {
  dining('dining', 'Dining & Food'),
  groceries('groceries', 'Groceries'),
  shopping('shopping', 'Shopping'),
  travel('travel', 'Travel'),
  fuel('fuel', 'Fuel'),
  utilities('utilities', 'Bills & Utilities'),
  entertainment('entertainment', 'Entertainment'),
  subscriptions('subscriptions', 'Subscriptions'),
  health('health', 'Health & Pharmacy'),
  education('education', 'Education'),
  rent('rent', 'Rent & Housing'),
  fees('fees', 'Fees & Charges'),
  wallet('wallet', 'Wallet & Transfers'),
  other('other', 'Other');

  const SpendCategory(this.slug, this.label);

  /// Stable wire identifier used in cache and API payloads.
  final String slug;

  /// Human readable label.
  final String label;

  /// Resolves a slug back to a category, defaulting to [SpendCategory.other].
  static SpendCategory fromSlug(String? slug) {
    for (final c in SpendCategory.values) {
      if (c.slug == slug) return c;
    }
    return SpendCategory.other;
  }
}
