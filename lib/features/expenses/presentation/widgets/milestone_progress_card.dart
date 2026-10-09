import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../domain/entities/card_milestone.dart';
import 'insights_section.dart';

/// Fee-waiver / reward milestone progress computed from tracked spends.
class MilestoneProgressCard extends StatelessWidget {
  final List<MilestoneProgress> milestones;
  final int index;

  const MilestoneProgressCard({super.key, required this.milestones, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return InsightsSection(
      title: 'Card milestones',
      subtitle: 'Based on spends tracked from SMS',
      icon: AppIcons.milestone,
      index: index,
      child: Column(children: [for (final m in milestones) _MilestoneRow(progress: m)]),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final MilestoneProgress progress;

  const _MilestoneRow({required this.progress});

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');

  IconData get _icon => switch (progress.milestone.type) {
        MilestoneType.feeWaiver => AppIcons.feeFree,
        MilestoneType.bonusRewards => AppIcons.rewardPoints,
        MilestoneType.loungeAccess => AppIcons.lounge,
        MilestoneType.voucher => AppIcons.cashback,
      };

  @override
  Widget build(BuildContext context) {
    final m = progress.milestone;
    final String status;
    final LuxuryBadgeVariant variant;
    if (progress.isAchieved) {
      status = 'Unlocked';
      variant = LuxuryBadgeVariant.emerald;
    } else if (progress.isAtRisk) {
      status = 'At risk';
      variant = LuxuryBadgeVariant.danger;
    } else {
      status = 'On track';
      variant = LuxuryBadgeVariant.sapphire;
    }

    final projection = progress.isAchieved
        ? m.rewardDescription
        : progress.projectedCompletion == null
            ? '${CurrencyFormatter.format(progress.remaining)} to go'
            : '${CurrencyFormatter.format(progress.remaining)} to go • ETA ${_dateFormat.format(progress.projectedCompletion!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: AppDimensions.iconSm, color: AppColors.goldLight),
              const SizedBox(width: AppDimensions.p8),
              Expanded(
                child: Text('${progress.cardLabel} • ${m.title}', style: AppTypography.titleSmall),
              ),
              LuxuryBadge(label: status, variant: variant, isSmall: true),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          SpendProgressBar(
            value: progress.progress,
            color: progress.isAchieved ? AppColors.emerald : AppColors.gold,
          ),
          const SizedBox(height: AppDimensions.p4),
          Row(
            children: [
              Expanded(child: Text(projection, style: AppTypography.bodySmall)),
              Text(
                '${CurrencyFormatter.formatCompact(progress.spent)} / ${CurrencyFormatter.formatCompact(m.targetSpend)}',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
