/// Spend Category domain entity (Dining, Flights, Grocery, etc.)
class SpendCategory {
  final int id;
  final String name;
  final String slug;
  final String? iconName;
  final String description;
  final int displayOrder;

  const SpendCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.iconName,
    this.description = '',
    this.displayOrder = 0,
  });
}
