import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/animated_amount.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../catalog/presentation/screens/card_detail_screen.dart';
import '../../../shell/presentation/providers/navigation_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/recommendation.dart';
import '../providers/advisor_provider.dart';

class AdvisorScreen extends StatelessWidget {
  const AdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<AdvisorProvider>().refresh(),
        edgeOffset: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            const _HomeAppBar(),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: const SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _WalletPulse(),
                  SizedBox(height: AppDimensions.p16),
                  _SpendInputCard(),
                  SizedBox(height: AppDimensions.p20),
                  Overline(AppStrings.homeQuestion),
                  SizedBox(height: AppDimensions.p10),
                  _CategoryGrid(),
                  SizedBox(height: AppDimensions.p24),
                  _ResultSection(),
                ]),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: context.navClearance)),
          ],
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.select<AuthProvider, String>((a) => a.user?.firstName ?? 'there');
    final initials = context.select<AuthProvider, String>((a) => a.user?.initials ?? 'G');
    final gutter = context.gutter();

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 112,
      titleSpacing: gutter,
      title: Builder(builder: (context) {
        final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
        final collapsed = settings == null || settings.currentExtent <= settings.minExtent + 8;
        return AnimatedOpacity(
          duration: AppDimensions.fastAnim,
          opacity: collapsed ? 1 : 0,
          child: Text(AppStrings.appName, style: context.text.titleMedium),
        );
      }),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: gutter),
          child: PressableScale(
            onTap: () => context.read<NavigationProvider>().setIndex(NavigationProvider.account),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: c.tint(c.accent, 0.18),
              child: Text(initials, style: context.text.labelMedium!.copyWith(color: c.accent)),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_greeting()}, $user', style: context.text.bodyMedium),
              const SizedBox(height: 2),
              Text('Which card should I use?', style: context.text.displaySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact wallet status: card count, next due date, vault state.
class _WalletPulse extends StatelessWidget {
  const _WalletPulse();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wallet = context.watch<WalletProvider>();
    final count = wallet.cards.length;

    if (count == 0 && wallet.state != ViewState.loading) {
      return InlineNotice(
        icon: AppIcons.cardholder,
        color: c.accent,
        message: 'Add your cards to get picks from your own wallet — tap to start.',
        onTap: () => context.read<NavigationProvider>().setIndex(NavigationProvider.wallet),
      );
    }

    final due = wallet.nextDueCard;
    final dueDate = due?.estimatedDueDate;
    final days = dueDate?.difference(DateTime.now()).inDays;

    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: _PulseTile(
              icon: AppIcons.navWallet,
              label: 'In wallet',
              value: '$count card${count == 1 ? '' : 's'}',
              onTap: () => context.read<NavigationProvider>().setIndex(NavigationProvider.wallet),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PulseTile(
              icon: AppIcons.calendar,
              label: 'Next due',
              value: days == null ? 'Set billing day' : (days <= 0 ? 'Today' : 'in $days days'),
              color: days != null && days <= 5 ? c.warning : null,
              onTap: () => context.read<NavigationProvider>().setIndex(NavigationProvider.wallet),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.mediumAnim);
  }
}

class _PulseTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  const _PulseTile({required this.icon, required this.label, required this.value, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: AppDimensions.roundedMd,
      child: Row(
        children: [
          IconHalo(icon: icon, size: 32, iconSize: 16, color: color ?? c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: context.text.bodySmall),
                Text(
                  value,
                  style: context.text.titleSmall!.copyWith(color: color ?? c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendInputCard extends StatefulWidget {
  const _SpendInputCard();

  @override
  State<_SpendInputCard> createState() => _SpendInputCardState();
}

/// Owns the amount TextEditingController.
class _SpendInputCardState extends State<_SpendInputCard> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<AdvisorProvider>().spendAmount.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuick(double v) {
    _controller.text = v.toStringAsFixed(0);
    context.read<AdvisorProvider>().setSpendAmount(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final advisor = context.watch<AdvisorProvider>();

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline(AppStrings.homeAmount),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('₹', style: AppTypography.numeric(26, color: c.textTertiary, weight: FontWeight.w500)),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  style: AppTypography.numeric(30, color: c.textPrimary),
                  cursorColor: c.accent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  onChanged: (v) {
                    final amount = double.tryParse(v);
                    if (amount != null && amount > 0) context.read<AdvisorProvider>().setSpendAmount(amount);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final q in AdvisorProvider.quickAmounts) ...[
                  AppChip(
                    label: CurrencyFormatter.compact(q),
                    selected: advisor.spendAmount == q,
                    onTap: () => _setQuick(q),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(AppIcons.international, size: 18, color: advisor.isInternational ? c.info : c.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.homeInternational, style: context.text.titleSmall),
                    Text(AppStrings.homeInternationalHint, style: context.text.bodySmall),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch.adaptive(
                  value: advisor.isInternational,
                  onChanged: (v) => context.read<AdvisorProvider>().setInternational(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const int _collapsedCount = 8;

  @override
  Widget build(BuildContext context) {
    final fromApi = context.select<CatalogProvider, List<SpendCategory>>((p) => p.categories);
    final categories = fromApi.isEmpty ? MockSeedData.categories : fromApi;
    final selected = context.select<AdvisorProvider, String>((p) => p.selectedCategory);
    final width = context.screenWidth - context.gutter() * 2;
    final columns = width >= 720 ? 8 : (width >= 480 ? 6 : 4);

    return _ExpandableGrid(
      collapsedCount: columns * 2 > _collapsedCount ? columns : _collapsedCount,
      columns: columns,
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final isSelected = cat.slug.toLowerCase() == selected.toLowerCase();
        return _CategoryTile(
          label: cat.name,
          icon: AppIcons.forCategory(cat.slug),
          selected: isSelected,
          onTap: () => context.read<AdvisorProvider>().setCategory(cat.slug),
        ).animate(delay: AppDimensions.staggerStep * (i % 8)).fadeIn(duration: AppDimensions.mediumAnim).scale(
              begin: const Offset(0.92, 0.92),
              duration: AppDimensions.mediumAnim,
              curve: Curves.easeOutBack,
            );
      },
    );
  }
}

class _ExpandableGrid extends StatefulWidget {
  final int collapsedCount;
  final int columns;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _ExpandableGrid({
    required this.collapsedCount,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<_ExpandableGrid> createState() => _ExpandableGridState();
}

/// Owns the expanded/collapsed notifier.
class _ExpandableGridState extends State<_ExpandableGrid> {
  final ValueNotifier<bool> _expanded = ValueNotifier(false);

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canExpand = widget.itemCount > widget.collapsedCount;
    return ValueListenableBuilder<bool>(
      valueListenable: _expanded,
      builder: (context, expanded, _) {
        final count = !canExpand || expanded ? widget.itemCount : widget.collapsedCount;
        return Column(
          children: [
            AnimatedSize(
              duration: AppDimensions.mediumAnim,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 76,
                ),
                itemCount: count,
                itemBuilder: widget.itemBuilder,
              ),
            ),
            if (canExpand)
              PressableScale(
                onTap: () => _expanded.value = !expanded,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(expanded ? 'Show less' : 'All categories', style: context.text.labelMedium),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: AppDimensions.mediumAnim,
                        child: Icon(AppIcons.chevronDown, size: 14, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.93,
      child: AnimatedContainer(
        duration: AppDimensions.fastAnim,
        decoration: BoxDecoration(
          color: selected ? c.tint(c.accent, c.isDark ? 0.14 : 0.10) : c.surface,
          borderRadius: AppDimensions.roundedMd,
          border: Border.all(color: selected ? c.tint(c.accent, 0.5) : c.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: selected ? c.accent : c.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.labelSmall!.copyWith(
                color: selected ? c.textPrimary : c.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection();

  @override
  Widget build(BuildContext context) {
    final advisor = context.watch<AdvisorProvider>();
    final rec = advisor.recommendation;

    if (rec == null) {
      if (advisor.state == ViewState.error) {
        return ErrorStateView(
          message: advisor.errorMessage ?? AppStrings.generalError,
          onRetry: () => context.read<AdvisorProvider>().refresh(),
        );
      }
      return const Column(
        children: [
          SkeletonBox(height: 150, borderRadius: AppDimensions.roundedLg),
          SizedBox(height: 12),
          SkeletonRow(),
          SkeletonRow(),
        ],
      );
    }

    final hero = rec.topCard ?? rec.marketBest;
    return AnimatedOpacity(
      duration: AppDimensions.fastAnim,
      opacity: advisor.state == ViewState.refreshing ? 0.6 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Overline(rec.hasWalletPick ? AppStrings.homeBestCard : AppStrings.homeBenchmark)),
              if (advisor.state == ViewState.refreshing)
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6)),
            ],
          ),
          const SizedBox(height: 10),
          if (hero != null)
            _HeroPick(option: hero, spend: rec.spendAmount, isWalletPick: rec.hasWalletPick, source: rec.source),
          if (rec.hasWalletPick && rec.missedValue >= 1 && rec.marketBest != null) ...[
            const SizedBox(height: 10),
            _MissedValueBanner(best: rec.marketBest!, missed: rec.missedValue),
          ],
          if (!rec.hasWalletPick) ...[
            const SizedBox(height: 10),
            InlineNotice(
              icon: AppIcons.lightbulb,
              color: context.colors.accent,
              message: 'This is the best card in the market for this spend. Add your own cards to see which one to use.',
              onTap: () => context.read<NavigationProvider>().setIndex(NavigationProvider.wallet),
            ),
          ],
          if (rec.alternatives.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.p24),
            const Overline(AppStrings.homeAlternatives),
            const SizedBox(height: 10),
            AppSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rec.alternatives.length; i++) ...[
                    if (i > 0) Divider(height: 1, indent: 64, color: context.colors.border),
                    _AlternativeRow(option: rec.alternatives[i], rank: i + 2, best: hero),
                  ],
                ],
              ),
            ),
          ],
          if (rec.insights.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.p24),
            const Overline(AppStrings.homeInsights),
            const SizedBox(height: 10),
            for (final insight in rec.insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InlineNotice(icon: AppIcons.lightbulb, message: insight, color: context.colors.warning),
              ),
          ],
        ],
      ),
    );
  }
}

class _HeroPick extends StatelessWidget {
  final RecommendationOption option;
  final double spend;
  final bool isWalletPick;
  final RecommendationSource source;

  const _HeroPick({required this.option, required this.spend, required this.isWalletPick, required this.source});

  Future<void> _copy(BuildContext context) async {
    final id = option.userCardId;
    if (id == null) return;
    final status = await context.read<WalletProvider>().copyCardNumber(id);
    if (!context.mounted) return;
    AppToast.vault(context, status, successMessage: 'Card number copied. Clears automatically.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canCopy = isWalletPick &&
        option.userCardId != null &&
        context.select<WalletProvider, bool>(
          (w) => w.cards.any((card) => card.id == option.userCardId && card.hasVaultDetails),
        );

    return AppSurface(
      tone: SurfaceTone.accent,
      elevated: true,
      padding: const EdgeInsets.all(16),
      onTap: option.cardSlug == null ? null : () => CardDetailScreen.open(context, slug: option.cardSlug!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardThumb(
                cardName: option.cardName,
                bankName: option.bankName,
                imageUrl: option.imageUrl,
                width: 92,
                last4: option.last4Digits,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.crown, size: 13, color: c.accent),
                        const SizedBox(width: 4),
                        Text(isWalletPick ? 'Use this card' : 'Top in market',
                            style: context.text.labelSmall!.copyWith(color: c.accent)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.nickname?.isNotEmpty ?? false ? option.nickname! : option.cardName,
                      style: context.text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [option.bankName, if (option.last4Digits != null) '•• ${option.last4Digits}'].join('  ·  '),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You earn', style: context.text.bodySmall),
                    AnimatedAmount(
                      value: option.estimatedValue,
                      style: AppTypography.numeric(26, color: c.success),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Return', style: context.text.bodySmall),
                  AnimatedAmount(
                    value: option.returnPercentage,
                    isPercent: true,
                    style: AppTypography.numeric(18, color: c.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          if (option.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(option.reason, style: context.text.bodySmall!.copyWith(color: c.textSecondary)),
          ],
          if (option.notes != null && option.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(option.notes!, style: context.text.bodySmall),
          ],
          if (canCopy) ...[
            const SizedBox(height: 14),
            AppButton(
              label: AppStrings.copyNumber,
              icon: AppIcons.fingerprint,
              compact: true,
              onPressed: () => _copy(context),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(source == RecommendationSource.onDevice ? AppIcons.lock : AppIcons.seal,
                  size: 12, color: c.textTertiary),
              const SizedBox(width: 4),
              Text(
                source == RecommendationSource.onDevice ? 'Ranked on your device' : 'Ranked by CreditVance',
                style: context.text.labelSmall,
              ),
            ],
          ),
        ],
      ),
    ).animate(key: ValueKey('${option.cardId}-$spend')).fadeIn(duration: AppDimensions.mediumAnim).slideY(begin: 0.04, end: 0);
  }
}

class _MissedValueBanner extends StatelessWidget {
  final RecommendationOption best;
  final double missed;

  const _MissedValueBanner({required this.best, required this.missed});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppSurface(
      tone: SurfaceTone.accent,
      tintColor: c.info,
      padding: const EdgeInsets.all(12),
      borderRadius: AppDimensions.roundedMd,
      onTap: best.cardSlug == null ? null : () => CardDetailScreen.open(context, slug: best.cardSlug!),
      child: Row(
        children: [
          IconHalo(icon: AppIcons.trendUp, color: c.info, size: 32, iconSize: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: best.cardName, style: context.text.labelMedium!.copyWith(color: c.textPrimary)),
                const TextSpan(text: ' would earn '),
                TextSpan(
                  text: '${CurrencyFormatter.format(missed)} more',
                  style: context.text.labelMedium!.copyWith(color: c.info),
                ),
                const TextSpan(text: ' on this spend.'),
              ]),
              style: context.text.bodySmall!.copyWith(color: c.textSecondary),
            ),
          ),
          Icon(AppIcons.chevronRight, size: 14, color: c.textTertiary),
        ],
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  final RecommendationOption option;
  final int rank;
  final RecommendationOption? best;

  const _AlternativeRow({required this.option, required this.rank, required this.best});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final diff = best == null ? 0.0 : best!.estimatedValue - option.estimatedValue;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(64, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: SizedBox(
          width: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CardThumb(cardName: option.cardName, bankName: option.bankName, imageUrl: option.imageUrl, width: 44),
              Positioned(
                left: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: AppDimensions.roundedFull),
                  child: Text('#$rank', style: context.text.labelSmall!.copyWith(fontSize: 9, color: c.textPrimary)),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          option.nickname?.isNotEmpty ?? false ? option.nickname! : option.cardName,
          style: context.text.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${CurrencyFormatter.formatPercentage(option.returnPercentage)} return',
          style: context.text.bodySmall,
        ),
        trailing: Text(
          CurrencyFormatter.format(option.estimatedValue),
          style: AppTypography.numeric(14, color: c.textPrimary),
        ),
        children: [
          if (option.reason.isNotEmpty) Text(option.reason, style: context.text.bodySmall),
          if (diff > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${CurrencyFormatter.format(diff)} less than the top pick',
              style: context.text.bodySmall!.copyWith(color: c.warning),
            ),
          ],
          if (option.cardSlug != null) ...[
            const SizedBox(height: 8),
            AppButton.ghost(
              label: 'View card',
              icon: AppIcons.arrowRight,
              trailingIcon: true,
              onPressed: () => CardDetailScreen.open(context, slug: option.cardSlug!),
            ),
          ],
        ],
      ),
    );
  }
}
