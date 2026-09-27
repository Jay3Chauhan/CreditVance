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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../calculator/presentation/providers/calculator_provider.dart';
import '../../../content/content_actions.dart';
import '../../../remote_config/presentation/remote_config_controller.dart';
import '../../../content/presentation/providers/home_provider.dart';
import '../../../content/presentation/widgets/home_feed.dart';
import '../../../content/domain/content_models.dart';
import '../../../content/presentation/providers/shortlist_provider.dart';
import '../../../shell/presentation/providers/navigation_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/screens/add_card_screen.dart';
import '../../data/models/catalog_card_model.dart';
import '../../domain/entities/card_tab.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../providers/card_detail_provider.dart';
import '../providers/catalog_provider.dart';
import 'compare_screen.dart';

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
                _KeyNumbers(card: card),
                const SizedBox(height: AppDimensions.p12),
                _EstimateCard(card: card),
                if (card.overview != null && card.overview!.isNotEmpty) ...[
                  const SectionHeader(title: 'About this card', padding: EdgeInsets.fromLTRB(0, AppDimensions.p24, 0, AppDimensions.p8)),
                  _Overview(text: card.overview!),
                ],
                ..._sections(context, card, p.tabs),
                const SectionHeader(title: 'Fees & value', padding: EdgeInsets.fromLTRB(0, AppDimensions.p24, 0, AppDimensions.p10)),
                _FeeSheet(card: card),
                if (card.applyLink != null) ...[
                  const SizedBox(height: AppDimensions.p16),
                  AppButton.outline(
                    label: 'Apply on the bank site',
                    icon: AppIcons.arrowUpRight,
                    onPressed: () => openExternalUrl(context, card.applyLink!),
                  ),
                ],
                _CardPromos(slug: card.slug),
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

    if (card.earnRates.isNotEmpty && !apiTabs.containsKey('earn-categories')) {
      sections.add(_ExpandableSection(
        icon: AppIcons.percent,
        title: 'Reward rates',
        initiallyExpanded: true,
        child: _RateBars(
          rows: [
            for (final rate in card.earnRates)
              (
                icon: AppIcons.forCategory(rate.categorySlug),
                label: rate.categorySlug,
                value: CurrencyFormatter.formatPercentage(rate.ratePercent),
                amount: rate.ratePercent,
                note: rate.capMonthly == null ? null : 'Capped at ${CurrencyFormatter.compact(rate.capMonthly!)}/month',
              ),
          ],
        ),
      ));
    }

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
      actions: const [_SaveAction(), SizedBox(width: 12)],
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

class _SaveAction extends StatelessWidget {
  const _SaveAction();

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardDetailProvider>().card!;
    final saved = context.select<ShortlistProvider, bool>((s) => s.isSaved(card.id));
    return AppIconButton(
      icon: saved ? AppIcons.bookmarkFill : AppIcons.bookmark,
      color: saved ? context.colors.accent : null,
      tooltip: saved ? 'Saved' : 'Shortlist',
      onPressed: () async {
        if (!context.read<AuthProvider>().isSignedIn) {
          AppToast.info(context, message: 'Sign in to save cards you might apply for');
          return;
        }
        final ok = await context.read<ShortlistProvider>().toggle(card.id);
        if (!context.mounted || ok) return;
        AppToast.error(context, message: 'Could not update your shortlist');
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

class _KeyNumbers extends StatelessWidget {
  final CatalogCard card;
  const _KeyNumbers({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget cell(String label, String value, {Color? color}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.numeric(16, color: color ?? c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(label, style: context.text.labelSmall, maxLines: 1),
              ],
            ),
          ),
        );
    Widget divider() => VerticalDivider(width: 1, thickness: 1, color: c.border);

    return AppSurface(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            cell('Reward return', card.returnLabel, color: c.accent),
            divider(),
            cell('Annual fee', card.annualFee == 0 ? 'Free' : CurrencyFormatter.compact(card.annualFee)),
            divider(),
            cell('Forex markup', card.forexMarkup == null ? '—' : CurrencyFormatter.formatPercentage(card.forexMarkup!)),
          ],
        ),
      ),
    );
  }
}

class _FeeSheet extends StatelessWidget {
  final CatalogCard card;
  const _FeeSheet({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String money(double v) => v == 0 ? 'Free' : CurrencyFormatter.format(v);
    final rows = <(IconData, String, String)>[
      (AppIcons.tag, 'Joining fee', money(card.joiningFee)),
      (AppIcons.receipt, 'Annual fee', money(card.annualFee)),
      if (card.feeWaiverSpend != null && card.feeWaiverSpend! > 0)
        (AppIcons.seal, 'Annual fee waived at', '${CurrencyFormatter.compact(card.feeWaiverSpend!)} spend'),
      (AppIcons.international, 'Forex markup', card.forexMarkup == null ? '—' : CurrencyFormatter.formatPercentage(card.forexMarkup!)),
      if (card.pointValueInr != null) (AppIcons.coins, 'Value of 1 point', '₹${card.pointValueInr!.toStringAsFixed(2)}'),
      (AppIcons.card, 'Network', CatalogCardModel.formatNetwork(card.network)),
    ];
    return AppSurface(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 44, color: c.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 16, color: c.textTertiary),
                  const SizedBox(width: 14),
                  Expanded(child: Text(rows[i].$2, style: context.text.bodyMedium)),
                  Text(rows[i].$3, style: context.text.labelLarge!.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

typedef _RateRow = ({IconData icon, String label, String value, double amount, String? note});

/// Horizontal bars scaled to the best rate on the card.
class _RateBars extends StatelessWidget {
  final List<_RateRow> rows;
  const _RateBars({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final max = rows.fold<double>(0, (m, r) => r.amount > m ? r.amount : m);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(row.icon, size: 14, color: c.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(row.label, style: context.text.bodyMedium!.copyWith(color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text(row.value, style: AppTypography.numeric(12.5, color: row.amount == max ? c.accent : c.textPrimary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: AppDimensions.roundedFull,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: max == 0 ? 0 : row.amount / max),
                    duration: AppDimensions.slowAnim,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: c.surfaceHigh,
                      color: row.amount == max ? c.accent : c.tint(c.accent, 0.45),
                    ),
                  ),
                ),
                if (row.note != null) ...[
                  const SizedBox(height: 4),
                  Text(row.note!, style: context.text.labelSmall),
                ],
              ],
            ),
          ),
      ],
    );
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
      tintColor: c.accent,
      padding: const EdgeInsets.all(14),
      onTap: () {
        calc.selectCatalogCard(card);
        context.read<NavigationProvider>().setIndex(NavigationProvider.rewards);
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Row(
        children: [
          IconHalo(icon: AppIcons.calculator),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net value on your spends', style: context.text.bodySmall),
                Text(
                  '${CurrencyFormatter.format(net)} / year',
                  style: AppTypography.numeric(17, color: net >= 0 ? c.textPrimary : c.danger),
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
        if (tab.earnRates.isNotEmpty)
          _RateBars(
            rows: [
              for (final row in tab.earnRates)
                (
                  icon: AppIcons.forCategory(row.category ?? row.name),
                  label: row.name,
                  value: row.label,
                  amount: row.pointsPerHundred,
                  note: null,
                ),
            ],
          ),
        if (tab.earnRates.isNotEmpty && tab.bullets.isNotEmpty) const SizedBox(height: 8),
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

class _CardPromos extends StatefulWidget {
  final String slug;
  const _CardPromos({required this.slug});

  @override
  State<_CardPromos> createState() => _CardPromosState();
}

/// Triggers the one-off promotions fetch for this card.
class _CardPromosState extends State<_CardPromos> {
  @override
  void initState() {
    super.initState();
    context.read<HomeProvider>().loadCardPromotions(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    final promos = context.select<HomeProvider, List<Promotion>>((h) => h.promotionsForCard(widget.slug));
    if (promos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Offers & guides', padding: EdgeInsets.fromLTRB(0, AppDimensions.p24, 0, AppDimensions.p10)),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: promos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(width: 236, child: PromoCard(promo: promos[i])),
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppDimensions.mediumAnim);
  }
}

class _ActionBar extends StatelessWidget {
  final CatalogCard card;
  const _ActionBar({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final owned = context.select<WalletProvider, bool>((w) => w.cards.any((u) => u.cardId == card.id));
    return DecoratedBox(
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
                Expanded(child: _CompareButton(card: card)),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: owned ? 'In your wallet' : 'I have this card',
                    icon: owned ? AppIcons.check : AppIcons.add,
                    variant: owned ? AppButtonVariant.tonal : AppButtonVariant.primary,
                    onPressed: owned
                        ? () {
                            context.read<NavigationProvider>().setIndex(NavigationProvider.wallet);
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          }
                        : () => AddCardScreen.open(context, card: card),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The single entry point for building a comparison.
class _CompareButton extends StatelessWidget {
  final CatalogCard card;
  const _CompareButton({required this.card});

  @override
  Widget build(BuildContext context) {
    final (inCompare, count) = context.select<CatalogProvider, (bool, int)>(
      (p) => (p.isInCompare(card.id), p.compareList.length),
    );
    final ready = inCompare && count >= 2;
    return AppButton.outline(
      label: ready ? 'Compare $count' : (inCompare ? 'Added' : 'Compare'),
      icon: ready ? AppIcons.compareActive : (inCompare ? AppIcons.check : AppIcons.compare),
      onPressed: () {
        final catalog = context.read<CatalogProvider>();
        if (!context.read<RemoteConfigController>().config.compareEnabled) {
          AppToast.info(context, message: 'Comparing cards is turned off right now');
          return;
        }
        if (ready) {
          CompareScreen.open(context);
          return;
        }
        if (inCompare) {
          catalog.toggleCompare(card);
          return;
        }
        if (!catalog.toggleCompare(card)) {
          AppToast.info(context, message: 'You can compare up to ${CatalogProvider.maxCompare} cards');
        } else if (catalog.compareList.length < 2) {
          AppToast.info(context, message: 'Added. Open another card and tap Compare');
        }
      },
    );
  }
}
