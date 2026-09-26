import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/bank_logo.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../calculator/presentation/providers/calculator_provider.dart';
import '../../../shell/presentation/providers/navigation_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/screens/add_card_screen.dart';
import '../../data/models/catalog_card_model.dart';
import '../../domain/entities/card_tab.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../providers/card_detail_provider.dart';
import '../providers/catalog_provider.dart';

class CardDetailScreen extends StatelessWidget {
  final String slug;
  final CatalogCard? initial;

  const CardDetailScreen({super.key, required this.slug, this.initial});

  static Future<void> open(BuildContext context, {required String slug, CatalogCard? card}) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppDimensions.mediumAnim,
        reverseTransitionDuration: AppDimensions.mediumAnim,
        pageBuilder: (_, _, _) => CardDetailScreen(slug: slug, initial: card),
        transitionsBuilder: (_, a, s, child) => SharedAxisTransition(
          animation: a,
          secondaryAnimation: s,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CardDetailProvider(ctx.read<CatalogRepository>(), slug: slug, initial: initial),
      child: const _DetailBody(),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CardDetailProvider>();
    final card = p.card;

    if (card == null) {
      return Scaffold(
        appBar: AppBar(),
        body: p.state == ViewState.error
            ? ErrorStateView(message: p.error ?? AppStrings.generalError, onRetry: p.retry)
            : const Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [SkeletonBox(height: 200), SizedBox(height: 16), SkeletonRow(), SkeletonRow()]),
              ),
      );
    }

    final gutter = context.gutter();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _DetailAppBar(card: card),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TitleBlock(card: card),
                const SizedBox(height: AppDimensions.p16),
                _StatsGrid(card: card),
                const SizedBox(height: AppDimensions.p16),
                _EstimateCard(card: card),
                if (card.overview != null && card.overview!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.p16),
                  _Overview(text: card.overview!),
                ],
                const SizedBox(height: AppDimensions.p8),
                ..._sections(context, card, p.tabs),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(card: card),
    );
  }

  List<Widget> _sections(BuildContext context, CatalogCard card, Map<String, CardTab> apiTabs) {
    final c = context.colors;
    final sections = <Widget>[];

    for (final tab in apiTabs.values) {
      sections.add(_ExpandableSection(
        icon: AppIcons.forCategory(tab.name),
        title: _prettyTab(tab.name),
        initiallyExpanded: sections.isEmpty,
        child: _TabContent(tab: tab),
      ));
    }

    if (card.keyPerks.isNotEmpty) {
      sections.add(_ExpandableSection(
        icon: AppIcons.star,
        title: 'Highlights',
        initiallyExpanded: sections.isEmpty,
        child: _Bullets(items: card.keyPerks),
      ));
    }

    for (final entry in card.tabs.entries) {
      sections.add(_ExpandableSection(
        icon: entry.key.contains('lounge')
            ? AppIcons.lounge
            : entry.key.contains('milestone')
                ? AppIcons.milestone
                : AppIcons.coins,
        title: entry.value.title,
        subtitle: entry.value.description,
        child: _Bullets(items: entry.value.bulletPoints),
      ));
    }

    final lounges = card.loungeTypes.map(CatalogCardModel.loungeLabel).whereType<String>().toList();
    if (lounges.isNotEmpty && !card.tabs.keys.any((k) => k.contains('lounge'))) {
      sections.add(_ExpandableSection(
        icon: AppIcons.lounge,
        title: 'Lounge access',
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final l in lounges) AppTag(label: l, color: c.info, icon: AppIcons.lounge)],
        ),
      ));
    }

    final benefits = card.benefitTypes.map(CatalogCardModel.benefitLabel).whereType<String>().toList();
    if (benefits.isNotEmpty) {
      sections.add(_ExpandableSection(
        icon: AppIcons.gift,
        title: 'Benefits',
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final b in benefits) AppTag(label: b, color: c.accent)],
        ),
      ));
    }

    return [
      for (var i = 0; i < sections.length; i++)
        sections[i].animate().fadeIn(delay: AppDimensions.staggerStep * i, duration: AppDimensions.mediumAnim),
    ];
  }

  static String _prettyTab(String slug) =>
      slug.split(RegExp(r'[-_]')).map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
}

class _DetailAppBar extends StatelessWidget {
  final CatalogCard card;
  const _DetailAppBar({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final skin = CardSkin.resolve(cardName: card.name, bankName: card.bankName);
    final cardWidth = (context.screenWidth * 0.62).clamp(200.0, 320.0);
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: cardWidth / AppDimensions.cardAspectRatio + 110,
      title: Text(card.shortName, style: context.text.titleMedium),
      actions: const [_CompareAction(), SizedBox(width: 8)],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.tint(skin.accent, c.isDark ? 0.18 : 0.22), c.canvas],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: CardThumb(
                  cardName: card.name,
                  bankName: card.bankName,
                  network: card.network,
                  imageUrl: card.imageUrl,
                  width: cardWidth,
                ).animate().fadeIn(duration: AppDimensions.slowAnim).scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutBack,
                      duration: AppDimensions.slowAnim,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareAction extends StatelessWidget {
  const _CompareAction();

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardDetailProvider>().card!;
    final inCompare = context.select<CatalogProvider, bool>((p) => p.isInCompare(card.id));
    return AppIconButton(
      icon: inCompare ? AppIcons.compareActive : AppIcons.compare,
      color: inCompare ? context.colors.accent : null,
      tooltip: 'Compare',
      onPressed: () {
        final ok = context.read<CatalogProvider>().toggleCompare(card);
        if (!ok) {
          AppToast.info(context, message: 'You can compare up to ${CatalogProvider.maxCompare} cards');
        } else if (!inCompare) {
          AppToast.success(context, message: 'Added to compare');
        }
      },
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final CatalogCard card;
  const _TitleBlock({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BankLogo(url: card.bankLogoUrl, bankName: card.bankName, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.name, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  AppTag(label: CatalogCardModel.formatNetwork(card.network)),
                  if (card.isLifetimeFree) AppTag(label: 'Lifetime free', color: c.success),
                  if (card.isPopular) AppTag(label: 'Popular', color: c.accent, icon: AppIcons.star),
                  if (!card.isCurrentlyIssuing) AppTag(label: 'Not issuing now', color: c.danger),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final CatalogCard card;
  const _StatsGrid({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stats = [
      ('Reward return', card.returnLabel, AppIcons.percent, c.success),
      ('Annual fee', card.annualFee == 0 ? 'Free' : CurrencyFormatter.format(card.annualFee), AppIcons.receipt, c.textPrimary),
      ('Joining fee', card.joiningFee == 0 ? 'Free' : CurrencyFormatter.format(card.joiningFee), AppIcons.tag, c.textPrimary),
      ('Forex markup', card.forexMarkup == null ? '—' : CurrencyFormatter.formatPercentage(card.forexMarkup!), AppIcons.international, c.textPrimary),
    ];
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 560 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: cols == 4 ? 1.5 : 2.3,
        padding: EdgeInsets.zero,
        children: [
          for (final s in stats)
            AppSurface(
              padding: const EdgeInsets.all(12),
              borderRadius: AppDimensions.roundedMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(s.$3, size: 13, color: c.textTertiary),
                      const SizedBox(width: 5),
                      Flexible(child: Text(s.$1, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(s.$2, style: AppTypography.numeric(17, color: s.$4)),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// Quick yearly value estimate using the calculator's current spend profile.
class _EstimateCard extends StatelessWidget {
  final CatalogCard card;
  const _EstimateCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final calc = context.read<CalculatorProvider>();
    final monthly = calc.monthlyTotal;
    final yearlyEarn = monthly * 12 * card.baseReturnRate / 100;
    final net = yearlyEarn - card.annualFee;

    return AppSurface(
      tone: SurfaceTone.accent,
      tintColor: net >= 0 ? c.success : c.warning,
      padding: const EdgeInsets.all(14),
      onTap: () {
        calc.selectCatalogCard(card);
        context.read<NavigationProvider>().setIndex(NavigationProvider.rewards);
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Row(
        children: [
          IconHalo(icon: AppIcons.chartBar, color: net >= 0 ? c.success : c.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net value on your spends', style: context.text.bodySmall),
                Text(
                  '${CurrencyFormatter.format(net)} / year',
                  style: AppTypography.numeric(17, color: net >= 0 ? c.success : c.warning),
                ),
                Text(
                  'At ${CurrencyFormatter.compact(monthly)}/month · tap to customise',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, size: 14, color: c.textTertiary),
        ],
      ),
    );
  }
}

class _Overview extends StatefulWidget {
  final String text;
  const _Overview({required this.text});

  @override
  State<_Overview> createState() => _OverviewState();
}

/// Owns the "read more" notifier.
class _OverviewState extends State<_Overview> {
  final ValueNotifier<bool> _expanded = ValueNotifier(false);

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<bool>(
      valueListenable: _expanded,
      builder: (context, expanded, _) => GestureDetector(
        onTap: () => _expanded.value = !expanded,
        child: AnimatedSize(
          duration: AppDimensions.mediumAnim,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                style: context.text.bodyMedium,
                maxLines: expanded ? null : 3,
                overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(expanded ? 'Show less' : 'Read more', style: context.text.labelMedium!.copyWith(color: c.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  const _ExpandableSection({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppSurface(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            shape: const RoundedRectangleBorder(),
            collapsedShape: const RoundedRectangleBorder(),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            expandedAlignment: Alignment.centerLeft,
            leading: IconHalo(icon: icon, size: 32, iconSize: 16, color: c.textSecondary),
            title: Text(title, style: context.text.titleSmall),
            subtitle: subtitle == null ? null : Text(subtitle!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  const _Bullets({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(AppIcons.checkCircle, size: 13, color: c.success),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: context.text.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _TabContent extends StatelessWidget {
  final CardTab tab;
  const _TabContent({required this.tab});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in tab.earnRates)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(AppIcons.forCategory(row.category ?? row.name), size: 16, color: c.textSecondary),
                const SizedBox(width: 10),
                Expanded(child: Text(row.name, style: context.text.bodyMedium!.copyWith(color: c.textPrimary))),
                Text(row.label, style: AppTypography.numeric(13, color: c.success)),
              ],
            ),
          ),
        if (tab.bullets.isNotEmpty) _Bullets(items: tab.bullets),
        if (tab.exclusions.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Overline('Excluded'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final e in tab.exclusions) AppTag(label: e, color: c.danger)],
          ),
        ],
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final CatalogCard card;
  const _ActionBar({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final owned = context.select<WalletProvider, bool>((w) => w.cards.any((u) => u.cardId == card.id));
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: ContentWidth(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.returnLabel, style: AppTypography.numeric(16, color: c.success)),
                      Text('reward return', style: context.text.labelSmall),
                    ],
                  ),
                ),
                AppButton(
                  label: owned ? 'In your wallet' : 'I have this card',
                  icon: owned ? AppIcons.check : AppIcons.add,
                  expand: false,
                  variant: owned ? AppButtonVariant.tonal : AppButtonVariant.primary,
                  onPressed: owned
                      ? () {
                          context.read<NavigationProvider>().setIndex(NavigationProvider.wallet);
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      : () => AddCardScreen.open(context, card: card),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
