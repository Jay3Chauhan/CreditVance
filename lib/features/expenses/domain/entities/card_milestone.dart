/// Kind of benefit unlocked when a spend milestone is reached.
enum MilestoneType {
  feeWaiver('fee_waiver'),
  bonusRewards('bonus_rewards'),
  loungeAccess('lounge_access'),
  voucher('voucher');

  const MilestoneType(this.slug);
  final String slug;

  /// Resolves a wire slug, defaulting to [MilestoneType.bonusRewards].
  static MilestoneType fromSlug(String? slug) {
    for (final t in MilestoneType.values) {
      if (t.slug == slug) return t;
    }
    return MilestoneType.bonusRewards;
  }
}

/// Window over which milestone spend is accumulated.
enum MilestonePeriod {
  calendarMonth('calendar_month'),
  calendarQuarter('calendar_quarter'),
  calendarYear('calendar_year'),

  /// Card-membership year starting in [CardMilestone.anniversaryMonth].
  cardYear('card_year');

  const MilestonePeriod(this.slug);
  final String slug;

  /// Resolves a wire slug, defaulting to [MilestonePeriod.cardYear].
  static MilestonePeriod fromSlug(String? slug) {
    for (final p in MilestonePeriod.values) {
      if (p.slug == slug) return p;
    }
    return MilestonePeriod.cardYear;
  }
}

/// A spend-threshold benefit attached to a saved card
/// (e.g. "annual fee waived on ₹4L spend in a card year").
class CardMilestone {
  final String id;
  final int userCardId;
  final String title;
  final String rewardDescription;
  final MilestoneType type;
  final MilestonePeriod period;
  final double targetSpend;

  /// 1-12; only used for [MilestonePeriod.cardYear]. Defaults to January.
  final int anniversaryMonth;

  const CardMilestone({
    required this.id,
    required this.userCardId,
    required this.title,
    required this.rewardDescription,
    required this.type,
    required this.period,
    required this.targetSpend,
    this.anniversaryMonth = 1,
  });
}

/// Progress towards a [CardMilestone], computed from parsed spend.
class MilestoneProgress {
  final CardMilestone milestone;
  final String cardLabel;
  final double spent;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// Date the target is projected to be hit at the current run rate.
  final DateTime? projectedCompletion;

  const MilestoneProgress({
    required this.milestone,
    required this.cardLabel,
    required this.spent,
    required this.windowStart,
    required this.windowEnd,
    this.projectedCompletion,
  });

  double get progress =>
      milestone.targetSpend <= 0 ? 0 : (spent / milestone.targetSpend).clamp(0.0, 1.0);

  double get remaining => (milestone.targetSpend - spent).clamp(0.0, double.infinity);

  bool get isAchieved => spent >= milestone.targetSpend;

  /// True when the projected completion falls after the window closes.
  bool get isAtRisk =>
      !isAchieved && (projectedCompletion == null || projectedCompletion!.isAfter(windowEnd));
}
