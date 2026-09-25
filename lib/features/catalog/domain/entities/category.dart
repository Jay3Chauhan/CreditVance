/// Spend Category domain entity (Dining, Flights, Grocery, etc.)
class SpendCategory {
  final int id;
  final String name;
  final String slug;
  final String? iconName;
  final String description;

  const SpendCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.iconName,
    this.description = '',
  });
}
