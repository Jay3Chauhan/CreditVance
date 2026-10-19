import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/spend_analytics.dart';
import 'insights_section.dart';

/// Per-card spend split, with latest available limit and unlinked-card hints.
class CardSpendCard extends StatelessWidget {
  final List<CardSpend> cards;
  final int index;

  const CardSpendCard({super.key, required this.cards, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return InsightsSection(
      title: 'Spend by card',
      subtitle: 'Matched to your vault by last 4 digits',
      icon: AppIcons.navWallet,
      accent: context.colors.success,
      index: index,
      child: Column(
        children: [for (final c in cards) _CardRow(card: c)],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final CardSpend card;

  const _CardRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIconTile(icon: AppIcons.contactless, color: c.success, size: AppDimensions.avatarSm),
              const SizedBox(width: AppDimensions.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.label, style: context.text.titleSmall ?? AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      card.latestAvailableLimit == null
                          ? '${card.count} spends'
                          : '${card.count} spends • Avl limit ${CurrencyFormatter.format(card.latestAvailableLimit!)}',
                      style: context.text.bodySmall ?? AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(CurrencyFormatter.format(card.amount), style: context.text.titleSmall ?? AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          SpendProgressBar(value: card.share, color: c.success),
          if (card.isUnlinked) ...[
            const SizedBox(height: AppDimensions.p8),
            Row(
              children: [
                Icon(AppIcons.info, size: AppDimensions.iconXs, color: c.textTertiary),
                const SizedBox(width: AppDimensions.p4),
                Expanded(
                  child: Text(
                    'Not in your vault — add it to unlock milestones',
                    style: context.text.bodySmall ?? AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
