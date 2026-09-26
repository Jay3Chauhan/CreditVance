import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bank_logo.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/catalog_provider.dart';
import '../widgets/catalog_card_tile.dart';
import '../widgets/catalog_filter_sheet.dart';
import 'compare_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  bool _onScroll(BuildContext context, ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 700) {
      context.read<CatalogProvider>().loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter(maxWidth: AppDimensions.wideContentMaxWidth);
    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) => _onScroll(context, n),
            child: RefreshIndicator(
              onRefresh: () => context.read<CatalogProvider>().refresh(),
              edgeOffset: 160,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  const _ExploreAppBar(),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
                    sliver: const _Results(),
                  ),
                  const SliverToBoxAdapter(child: _ListFooter()),
                  SliverToBoxAdapter(child: SizedBox(height: context.navClearance + 56)),
                ],
              ),
            ),
          ),
          const _CompareTray(),
        ],
      ),
    );
  }
}

class _ExploreAppBar extends StatelessWidget {
  const _ExploreAppBar();

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter(maxWidth: AppDimensions.wideContentMaxWidth);
    final total = context.select<CatalogProvider, int>((p) => p.total);
    return SliverAppBar(
      pinned: true,
      floating: true,
      titleSpacing: gutter,
      toolbarHeight: 60,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.exploreTitle, style: context.text.headlineMedium),
          AnimatedSwitcher(
            duration: AppDimensions.fastAnim,
            child: Text(
              total > 0 ? '$total cards' : 'Find your next card',
              key: ValueKey(total),
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(104),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 10),
              child: const Row(
                children: [
                  Expanded(child: _SearchField()),
                  SizedBox(width: 8),
                  _FilterButton(),
                ],
              ),
            ),
            const _QuickFilters(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

/// Owns the search TextEditingController.
class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: context.read<CatalogProvider>().query.search ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: AppDimensions.searchBarHeight,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) => AppTextField(
          controller: _controller,
          hint: AppStrings.exploreSearchHint,
          prefixIcon: AppIcons.search,
          textInputAction: TextInputAction.search,
          onChanged: (v) => context.read<CatalogProvider>().setSearchQuery(v),
          suffix: value.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(AppIcons.closeCircle, size: 16, color: c.textTertiary),
                  onPressed: () {
                    _controller.clear();
                    context.read<CatalogProvider>().setSearchQuery('');
                  },
                ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = context.select<CatalogProvider, int>((p) => p.query.activeFilterCount);
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: c.accent,
      textColor: c.onAccent,
      child: AppIconButton(
        icon: AppIcons.filter,
        size: AppDimensions.searchBarHeight,
        tooltip: 'Filters & sort',
        onPressed: () => showCatalogFilterSheet(context),
      ),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CatalogProvider>();
    final q = p.query;
    final gutter = context.gutter(maxWidth: AppDimensions.wideContentMaxWidth);
    return ChipStrip(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      children: [
        AppChip(
          label: 'Lifetime free',
          icon: AppIcons.tag,
          selected: q.feeType == 'free',
          onTap: () => p.setFeeFilter(q.feeType == 'free' ? null : 'free'),
        ),
        AppChip(
          label: 'Top returns',
          icon: AppIcons.trendUp,
          selected: q.sortBy == 'return',
          onTap: () => p.setSortBy(q.sortBy == 'return' ? 'popular' : 'return'),
        ),
        for (final bank in p.banks.take(14))
          AppChip(
            label: bank.name.replaceAll(RegExp(r'\s+Bank$', caseSensitive: false), ''),
            leading: BankLogo(url: bank.logoUrl, bankName: bank.name, size: 18),
            selected: q.bankSlug == bank.slug,
            onTap: () => p.setBankFilter(q.bankSlug == bank.slug ? null : bank.slug),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CatalogProvider>();
    final cards = p.cards;
    final width = context.screenWidth - context.gutter(maxWidth: AppDimensions.wideContentMaxWidth) * 2;
    final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);

    if (p.state == ViewState.loading || p.state == ViewState.initial) {
      return SliverList.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: SkeletonRow()),
      );
    }
    if (p.state == ViewState.error && cards.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateView(
          message: p.errorMessage ?? AppStrings.generalError,
          onRetry: () => context.read<CatalogProvider>().refresh(),
        ),
      );
    }
    if (cards.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView(
          icon: AppIcons.search,
          title: 'No cards found',
          message: 'Try a different search or clear some filters.',
          secondaryLabel: p.hasActiveFilters ? 'Clear filters' : null,
          onSecondary: () => context.read<CatalogProvider>().clearFilters(keepSearch: false),
        ),
      );
    }

    final header = p.isShowingCached
        ? const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: InlineNotice(icon: AppIcons.offline, message: AppStrings.offlineMessage),
            ),
          )
        : const SliverToBoxAdapter(child: SizedBox.shrink());

    Widget tile(int i) => CatalogCardTile(key: ValueKey(cards[i].id), card: cards[i])
        .animate()
        .fadeIn(duration: AppDimensions.mediumAnim, delay: AppDimensions.staggerStep * (i % 10))
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);

    return SliverMainAxisGroup(
      slivers: [
        header,
        if (columns == 1)
          SliverList.separated(
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => tile(i),
          )
        else
          SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 104,
            ),
            itemCount: cards.length,
            itemBuilder: (_, i) => tile(i),
          ),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CatalogProvider>();
    if (p.cards.isEmpty || p.state == ViewState.loading) return const SizedBox.shrink();

    Widget child;
    if (p.isLoadingMore) {
      child = const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (p.loadMoreError != null) {
      child = AppButton.outline(
        label: 'Couldn\'t load more · Retry',
        icon: AppIcons.refresh,
        compact: true,
        expand: false,
        onPressed: () => context.read<CatalogProvider>().loadMore(),
      );
    } else if (!p.hasNext) {
      child = Text(
        'You\'ve seen all ${p.cards.length} cards',
        style: context.text.bodySmall,
      );
    } else {
      child = const SizedBox(height: 20);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: child),
    );
  }
}

class _CompareTray extends StatelessWidget {
  const _CompareTray();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.select<CatalogProvider, int>((p) => p.compareList.length);
    final cards = context.read<CatalogProvider>().compareList;
    final bottom = context.navClearance - 8;

    return AnimatedPositioned(
      duration: AppDimensions.mediumAnim,
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      bottom: list == 0 ? -100 : bottom,
      child: ContentWidth(
        maxWidth: 480,
        child: AppSurface(
          tone: SurfaceTone.high,
          elevated: true,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          borderRadius: AppDimensions.roundedXl,
          child: Row(
            children: [
              SizedBox(
                height: 30,
                width: 34.0 + (list.clamp(1, 3) - 1) * 20,
                child: Stack(
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      Positioned(
                        left: i * 20.0,
                        child: CardThumb(cardName: cards[i].name, bankName: cards[i].bankName, imageUrl: cards[i].imageUrl, width: 44),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  list < 2 ? 'Pick one more to compare' : '$list cards selected',
                  style: context.text.labelMedium,
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.close, size: 16, color: c.textTertiary),
                onPressed: () => context.read<CatalogProvider>().clearCompare(),
              ),
              AppButton(
                label: 'Compare',
                compact: true,
                expand: false,
                onPressed: list < 2 ? null : () => CompareScreen.open(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
