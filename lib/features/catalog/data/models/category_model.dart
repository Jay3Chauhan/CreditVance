import '../../domain/entities/category.dart';

/// DTO for SpendCategory
class CategoryModel extends SpendCategory {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.iconName,
    super.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconName: json['icon_name'] as String?,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon_name': iconName,
        'description': description,
      };
}
