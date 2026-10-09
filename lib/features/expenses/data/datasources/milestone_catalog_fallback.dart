import '../../domain/entities/card_milestone.dart';
import '../../domain/entities/tracked_card_ref.dart';

class _MilestoneRule {
  final RegExp cardName;
  final String title;
  final String reward;
  final MilestoneType type;
  final double target;

  _MilestoneRule(String pattern, this.title, this.reward, this.type, this.target)
      : cardName = RegExp(pattern, caseSensitive: false);
}

/// Bundled milestone rules for popular cards, used offline or when the
/// backend milestones endpoint is unavailable.
///
/// Thresholds reflect publicly listed issuer terms at the time of writing and
/// must be served (and kept current) by the backend card catalog in production.
/// Without the card anniversary date the window defaults to the calendar year.
class MilestoneCatalogFallback {
  const MilestoneCatalogFallback();

  static final List<_MilestoneRule> _rules = [
    _MilestoneRule(r'infinia', 'Annual fee waiver', 'Renewal fee waived', MilestoneType.feeWaiver, 1000000),
    _MilestoneRule(r'regalia gold', 'Annual fee waiver', 'Renewal fee waived', MilestoneType.feeWaiver, 400000),
    _MilestoneRule(r'sbi cashback|cashback sbi', 'Annual fee waiver', 'Renewal fee reversed', MilestoneType.feeWaiver,
        200000),
    _MilestoneRule(r'atlas', 'Silver milestone', '2,500 bonus EDGE Miles', MilestoneType.bonusRewards, 300000),
    _MilestoneRule(r'atlas', 'Gold milestone', '2,500 more bonus EDGE Miles', MilestoneType.bonusRewards, 750000),
    _MilestoneRule(r'atlas', 'Platinum milestone', '5,000 more bonus EDGE Miles', MilestoneType.bonusRewards, 1500000),
    _MilestoneRule(r'platinum travel', 'Travel milestone 1', '15,000 bonus Membership Rewards',
        MilestoneType.bonusRewards, 190000),
    _MilestoneRule(r'platinum travel', 'Travel milestone 2', '25,000 bonus MR + Taj voucher',
        MilestoneType.voucher, 400000),
    _MilestoneRule(r'amazon pay', 'Lifetime free', 'No fee — track Prime savings instead', MilestoneType.bonusRewards,
        0),
  ];

  /// Milestones applicable to [cards] based on the catalog card name.
  List<CardMilestone> milestonesFor(List<TrackedCardRef> cards) {
    final out = <CardMilestone>[];
    for (final card in cards) {
      var index = 0;
      for (final rule in _rules) {
        if (rule.target <= 0 || !rule.cardName.hasMatch(card.cardName)) continue;
        out.add(CardMilestone(
          id: 'local_${card.userCardId}_${index++}',
          userCardId: card.userCardId,
          title: rule.title,
          rewardDescription: rule.reward,
          type: rule.type,
          period: MilestonePeriod.calendarYear,
          targetSpend: rule.target,
        ));
      }
    }
    return out;
  }
}
