import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../domain/entities/catalog_card.dart';
import '../providers/catalog_provider.dart';
import '../screens/card_detail_screen.dart';

/// Catalog list row. Actions (compare, shortlist, add) live on the detail page.
class CatalogCardTile extends StatelessWidget {
  final CatalogCard card;
  const CatalogCardTile({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final inCompare = context.select<CatalogProvider, bool>((p) => p.isInCompare(card.id));
    final fee = card.annualFee == 0 ? 'No annual fee' : '${CurrencyFormatter.compact(card.annualFee)} a year';
    final meta = [
      card.bankName,
      fee,
      if (!card.isCurrentlyIssuing) 'Not issuing',
    ].join(' · ');

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.roundedLg,
        side: BorderSide(color: inCompare ? c.tint(c.accent, 0.5) : c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticsHelper.selection();
          CardDetailScreen.open(context, slug: card.slug, card: card);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              CardThumb(
                cardName: card.name,
                bankName: card.bankName,
                network: card.network,
                imageUrl: card.imageUrl,
                width: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(card.shortName, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (card.isPopular) ...[
                          const SizedBox(width: 4),
                          Icon(AppIcons.star, size: 12, color: c.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: context.text.bodySmall!.copyWith(color: card.isCurrentlyIssuing ? null : c.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(card.returnLabel, style: AppTypography.numeric(14, color: c.textPrimary)),
                  Text('return', style: context.text.labelSmall),
                ],
              ),
              const SizedBox(width: 4),
              Icon(inCompare ? AppIcons.compareActive : AppIcons.chevronRight, size: 15, color: inCompare ? c.accent : c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
