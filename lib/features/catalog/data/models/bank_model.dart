import '../../domain/entities/bank.dart';

/// DTO for Bank entity
class BankModel extends Bank {
  const BankModel({
    required super.id,
    required super.name,
    required super.slug,
    super.logoUrl,
    super.cardCount,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      cardCount: json['total_cards'] as int? ?? json['card_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo_url': logoUrl,
        'total_cards': cardCount,
      };
}
