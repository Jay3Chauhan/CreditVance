import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../domain/entities/catalog_card.dart';
import '../providers/catalog_provider.dart';
import '../screens/card_detail_screen.dart';

/// Catalog list row; opens the detail page with a container transform.
class CatalogCardTile extends StatelessWidget {
  final CatalogCard card;
  const CatalogCardTile({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OpenContainer(
      transitionDuration: AppDimensions.slowAnim,
      closedElevation: 0,
      openElevation: 0,
      closedColor: c.surface,
      openColor: c.canvas,
      middleColor: c.canvas,
      closedShape: RoundedRectangleBorder(
        borderRadius: AppDimensions.roundedLg,
        side: BorderSide(color: c.border),
      ),
      tappable: false,
      openBuilder: (_, _) => CardDetailScreen(slug: card.slug, initial: card),
      closedBuilder: (context, open) => InkWell(
        onTap: () {
          HapticsHelper.selection();
          open();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CardThumb(
                cardName: card.name,
                bankName: card.bankName,
                network: card.network,
                imageUrl: card.imageUrl,
                width: 78,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.shortName, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 1),
                    Text(card.bankName, style: context.text.bodySmall, maxLines: 1),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (card.isLifetimeFree) AppTag(label: 'Lifetime free', color: c.success),
                        if (card.isPopular) AppTag(label: 'Popular', color: c.accent, icon: AppIcons.star),
                        if (card.hasLounge) AppTag(label: 'Lounge', icon: AppIcons.lounge, color: c.info),
                        if (!card.isCurrentlyIssuing) AppTag(label: 'Not issuing', color: c.danger),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(card.returnLabel, style: AppTypography.numeric(14, color: c.success)),
                  Text('return', style: context.text.labelSmall),
                  const SizedBox(height: 6),
                  Text(
                    card.annualFee == 0 ? 'Free' : CurrencyFormatter.compact(card.annualFee),
                    style: AppTypography.numeric(12, color: c.textSecondary, weight: FontWeight.w600),
                  ),
                ],
              ),
              _CompareToggle(card: card),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareToggle extends StatelessWidget {
  final CatalogCard card;
  const _CompareToggle({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = context.select<CatalogProvider, bool>((p) => p.isInCompare(card.id));
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: selected ? 'Remove from compare' : 'Add to compare',
      onPressed: () {
        HapticsHelper.selection();
        final ok = context.read<CatalogProvider>().toggleCompare(card);
        if (!ok) AppToast.info(context, message: 'You can compare up to ${CatalogProvider.maxCompare} cards');
      },
      icon: AnimatedSwitcher(
        duration: AppDimensions.fastAnim,
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: Icon(
          selected ? AppIcons.compareActive : AppIcons.compare,
          key: ValueKey(selected),
          size: 19,
          color: selected ? c.accent : c.textTertiary,
        ),
      ),
    );
  }
}
