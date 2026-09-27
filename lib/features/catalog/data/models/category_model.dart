import '../../domain/entities/category.dart';

/// DTO for SpendCategory
class CategoryModel extends SpendCategory {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.iconName,
    super.description,
    super.displayOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconName: json['icon_key'] as String? ?? json['icon_name'] as String?,
      description: json['description'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon_key': iconName,
        'icon_name': iconName,
        'display_order': displayOrder,
        'description': description,
      };
}
