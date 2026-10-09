import '../../domain/entities/card_milestone.dart';

/// DTO for [CardMilestone] returned by `GET /expenses/milestones`.
class CardMilestoneModel extends CardMilestone {
  const CardMilestoneModel({
    required super.id,
    required super.userCardId,
    required super.title,
    required super.rewardDescription,
    required super.type,
    required super.period,
    required super.targetSpend,
    super.anniversaryMonth,
  });

  factory CardMilestoneModel.fromJson(Map<String, dynamic> json) {
    return CardMilestoneModel(
      id: json['id'].toString(),
      userCardId: json['user_card_id'] as int,
      title: json['title'] as String? ?? 'Spend milestone',
      rewardDescription: json['reward_description'] as String? ?? '',
      type: MilestoneType.fromSlug(json['type'] as String?),
      period: MilestonePeriod.fromSlug(json['period'] as String?),
      targetSpend: (json['target_spend'] as num).toDouble(),
      anniversaryMonth: json['anniversary_month'] as int? ?? 1,
    );
  }
}
