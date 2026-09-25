/// Bank domain entity representing financial institutions.
class Bank {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final int cardCount;

  const Bank({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.cardCount = 0,
  });
}
