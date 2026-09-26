import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../calculator/domain/reward_engine.dart';
import '../../../calculator/presentation/providers/calculator_provider.dart';
import '../../data/models/catalog_card_model.dart';
import '../../domain/entities/catalog_card.dart';
import '../providers/catalog_provider.dart';
import 'card_detail_screen.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompareScreen()));

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CatalogProvider>().compareList;
    return Scaffold(
      appBar: AppBar(title: const Text('Compare cards')),
      body: cards.length < 2
          ? EmptyStateView(
              icon: AppIcons.compare,
              title: 'Pick at least 2 cards',
              message: 'Tap the scale icon on any card in Explore to add it here.',
              secondaryLabel: 'Back to Explore',
              onSecondary: () => Navigator.pop(context),
            )
          : _CompareTable(cards: cards),
    );
  }
}

class _Metric {
  final String label;
  final IconData icon;
  final String Function(CatalogCard) display;
  final double Function(CatalogCard)? score;
  final bool higherIsBetter;

  const _Metric(this.label, this.icon, this.display, {this.score, this.higherIsBetter = true});
}

class _CompareTable extends StatelessWidget {
  final List<CatalogCard> cards;
  const _CompareTable({required this.cards});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final calc = context.read<CalculatorProvider>();
    final monthly = calc.monthlyTotal;

    double net(CatalogCard card) => RewardEngine.calculate(
          CalculatorProvider.subjectFromCatalog(card),
          {for (final b in calc.result.breakdowns) b.bucket: b.spend / 12},
        ).netBenefit;

    final metrics = <_Metric>[
      _Metric('Net value / year', AppIcons.chartBar, (x) => CurrencyFormatter.format(net(x)), score: net),
      _Metric('Reward return', AppIcons.percent, (x) => x.returnLabel, score: (x) => x.maxReturnRate ?? x.baseReturnRate),
      _Metric('Annual fee', AppIcons.receipt, (x) => x.annualFee == 0 ? 'Free' : CurrencyFormatter.format(x.annualFee),
          score: (x) => x.annualFee, higherIsBetter: false),
      _Metric('Joining fee', AppIcons.tag, (x) => x.joiningFee == 0 ? 'Free' : CurrencyFormatter.format(x.joiningFee),
          score: (x) => x.joiningFee, higherIsBetter: false),
      _Metric('Forex markup', AppIcons.international,
          (x) => x.forexMarkup == null ? '—' : CurrencyFormatter.formatPercentage(x.forexMarkup!),
          score: (x) => x.forexMarkup ?? 99, higherIsBetter: false),
      _Metric('Lounge access', AppIcons.lounge, (x) => x.hasInternationalLounge ? 'Intl + domestic' : (x.hasLounge ? 'Domestic' : 'None'),
          score: (x) => x.hasInternationalLounge ? 2 : (x.hasLounge ? 1 : 0)),
      _Metric('Network', AppIcons.card, (x) => CatalogCardModel.formatNetwork(x.network)),
      _Metric('Benefits', AppIcons.gift, (x) => '${x.benefitTypes.length}', score: (x) => x.benefitTypes.length.toDouble()),
    ];

    return LayoutBuilder(builder: (context, box) {
      final labelWidth = box.maxWidth < 420 ? 104.0 : 150.0;
      final colWidth = ((box.maxWidth - labelWidth - 32) / cards.length).clamp(112.0, 260.0);
      final tableWidth = labelWidth + colWidth * cards.length;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net value uses your Rewards spend profile (${CurrencyFormatter.compact(monthly)}/month).',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: labelWidth),
                        for (final card in cards) SizedBox(width: colWidth, child: _ColumnHeader(card: card)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var m = 0; m < metrics.length; m++) ...[
                            if (m > 0) Divider(height: 1, color: c.border),
                            _MetricRow(metric: metrics[m], cards: cards, labelWidth: labelWidth, colWidth: colWidth),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: AppDimensions.mediumAnim);
    });
  }
}

class _ColumnHeader extends StatelessWidget {
  final CatalogCard card;
  const _ColumnHeader({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PressableScale(
                onTap: () => CardDetailScreen.open(context, slug: card.slug, card: card),
                child: CardThumb(cardName: card.name, bankName: card.bankName, network: card.network, imageUrl: card.imageUrl, width: 96),
              ),
              Positioned(
                right: -8,
                top: -8,
                child: PressableScale(
                  onTap: () => context.read<CatalogProvider>().toggleCompare(card),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: c.surfaceHigh, shape: BoxShape.circle, border: Border.all(color: c.border)),
                    child: Icon(AppIcons.close, size: 12, color: c.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(card.shortName, style: context.text.labelMedium!.copyWith(color: c.textPrimary), textAlign: TextAlign.center, maxLines: 2),
          Text(card.bankName, style: context.text.labelSmall, maxLines: 1),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final _Metric metric;
  final List<CatalogCard> cards;
  final double labelWidth;
  final double colWidth;

  const _MetricRow({required this.metric, required this.cards, required this.labelWidth, required this.colWidth});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    int? bestIndex;
    if (metric.score != null) {
      final scores = cards.map(metric.score!).toList();
      final best = metric.higherIsBetter ? scores.reduce((a, b) => a > b ? a : b) : scores.reduce((a, b) => a < b ? a : b);
      final winners = scores.where((s) => s == best).length;
      if (winners == 1) bestIndex = scores.indexOf(best);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Icon(metric.icon, size: 14, color: c.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(metric.label, style: context.text.bodySmall, maxLines: 2)),
                ],
              ),
            ),
          ),
          for (var i = 0; i < cards.length; i++)
            SizedBox(
              width: colWidth,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: i == bestIndex
                      ? BoxDecoration(color: c.tint(c.success, 0.14), borderRadius: AppDimensions.roundedSm)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i == bestIndex) ...[Icon(AppIcons.crown, size: 11, color: c.success), const SizedBox(width: 4)],
                      Flexible(
                        child: Text(
                          metric.display(cards[i]),
                          textAlign: TextAlign.center,
                          style: AppTypography.numeric(13, color: i == bestIndex ? c.success : c.textPrimary, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
