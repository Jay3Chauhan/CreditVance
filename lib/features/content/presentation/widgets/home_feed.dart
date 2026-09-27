import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../../catalog/presentation/screens/card_detail_screen.dart';
import '../../content_actions.dart';
import '../../domain/content_models.dart';
import '../providers/home_provider.dart';

/// Server maintenance message; the only server content allowed at the top of
/// a screen because it is tiny and usually absent.
class MaintenanceNotice extends StatelessWidget {
  const MaintenanceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select<HomeProvider, String?>((h) => h.maintenanceMessage);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InlineNotice(icon: AppIcons.warning, message: message, color: context.colors.warning),
    );
  }
}

/// Banners, tools, guides and collections from `GET /home`. Rendered below
/// the primary content so late responses never push the page down.
class HomeFeedSection extends StatelessWidget {
  const HomeFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.select<HomeProvider, HomeFeed?>((h) => h.feed);
    if (feed == null || feed.isEmpty) return const SizedBox.shrink();

    final banners = [...feed.heroBanners, ...feed.stripBanners];
    final tools = feed.quickActions.where((a) => !(a.action.target ?? '').startsWith('/advisor')).toList();
    final collections = [
      ...feed.collections.where((c) => c.cards.isNotEmpty),
      if (feed.popularCards.isNotEmpty)
        HomeCollection(
          key: 'popular',
          title: 'Popular right now',
          action: const ContentAction(type: 'screen', target: '/catalog?sort_by=popular', label: 'See all'),
          cards: feed.popularCards,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Discover',
          subtitle: 'Tools and guides to get more from your cards',
          padding: EdgeInsets.fromLTRB(0, AppDimensions.p32, 0, AppDimensions.p12),
        ),
        if (banners.isNotEmpty) BannerCarousel(banners: banners),
        if (tools.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.p12),
          _ToolGrid(actions: tools),
        ],
        if (feed.featuredPromotions.isNotEmpty) ...[
          const SectionHeader(title: 'Guides', padding: EdgeInsets.fromLTRB(0, AppDimensions.p24, 0, AppDimensions.p10)),
          _GuideRow(promotions: feed.featuredPromotions),
        ],
        for (final collection in collections) _CollectionRow(collection: collection),
      ],
    ).animate().fadeIn(duration: AppDimensions.mediumAnim);
  }
}

IconData _iconForAction(ContentAction action, {String? fallbackKey}) {
  final target = action.target ?? '';
  if (target.startsWith('/advisor')) return AppIcons.sparkles;
  if (target.startsWith('/compare')) return AppIcons.compare;
  if (target.startsWith('/calculator')) return AppIcons.calculator;
  if (target.contains('lounge')) return AppIcons.lounge;
  if (target.startsWith('/wallet')) return AppIcons.cardholder;
  if (target.startsWith('/catalog')) return AppIcons.navExplore;
  if (fallbackKey != null) return AppIcons.fromMaterial(fallbackKey);
  return AppIcons.gift;
}

/// Theme-consistent banner. Server colours are ignored so every placement
/// matches the active light / dark palette.
class PromoBanner extends StatefulWidget {
  final AppBanner banner;
  final bool compact;
  const PromoBanner({super.key, required this.banner, this.compact = false});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

/// Tracks a single impression per mount.
class _PromoBannerState extends State<PromoBanner> {
  @override
  void initState() {
    super.initState();
    context.read<HomeProvider>().trackBanner(widget.banner, 'impression');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final banner = widget.banner;
    return AppSurface(
      onTap: () {
        context.read<HomeProvider>().trackBanner(banner, 'click');
        openContentAction(context, banner.action);
      },
      padding: EdgeInsets.all(widget.compact ? 12 : 14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.tint(c.accent, c.isDark ? 0.16 : 0.12), c.surface],
      ),
      child: Row(
        children: [
          IconHalo(icon: _iconForAction(banner.action), size: widget.compact ? 36 : 42, iconSize: widget.compact ? 17 : 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner.badgeText != null && !widget.compact) ...[
                  Overline(banner.badgeText!, color: c.accent),
                  const SizedBox(height: 2),
                ],
                Text(banner.title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(banner.subtitle!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(AppIcons.arrowRight, size: 16, color: c.accent),
        ],
      ),
    );
  }
}

class BannerCarousel extends StatefulWidget {
  final List<AppBanner> banners;
  const BannerCarousel({super.key, required this.banners});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

/// Owns the page controller and the current-page notifier.
class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  final _index = ValueNotifier<int>(0);

  @override
  void dispose() {
    _controller.dispose();
    _index.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.length == 1) return PromoBanner(banner: banners.first);
    final c = context.colors;
    return Column(
      children: [
        SizedBox(
          height: 108,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) => _index.value = i,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: PromoBanner(banner: banners[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: _index,
          builder: (_, index, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < banners.length; i++)
                AnimatedContainer(
                  duration: AppDimensions.fastAnim,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == index ? c.accent : c.borderStrong,
                    borderRadius: AppDimensions.roundedFull,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolGrid extends StatelessWidget {
  final List<QuickAction> actions;
  const _ToolGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 560 ? 4 : 2;
      final width = (box.maxWidth - 8 * (cols - 1)) / cols;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final action in actions)
            SizedBox(
              width: width,
              child: AppSurface(
                onTap: () => openContentAction(context, action.action),
                padding: const EdgeInsets.all(12),
                borderRadius: AppDimensions.roundedMd,
                child: Row(
                  children: [
                    Icon(_iconForAction(action.action, fallbackKey: action.iconKey), size: 18, color: c.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(action.title, style: context.text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (action.subtitle != null)
                            Text(action.subtitle!, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _GuideRow extends StatelessWidget {
  final List<Promotion> promotions;
  const _GuideRow({required this.promotions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: promotions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(width: 236, child: PromoCard(promo: promotions[i])),
      ),
    );
  }
}

/// Compact editorial / offer card used for guides and card promotions.
class PromoCard extends StatefulWidget {
  final Promotion promo;
  const PromoCard({super.key, required this.promo});

  @override
  State<PromoCard> createState() => _PromoCardState();
}

/// Tracks a single impression per mount.
class _PromoCardState extends State<PromoCard> {
  @override
  void initState() {
    super.initState();
    context.read<HomeProvider>().trackPromotion(widget.promo, 'impression');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final promo = widget.promo;
    return AppSurface(
      onTap: () {
        context.read<HomeProvider>().trackPromotion(promo, 'click');
        openContentAction(context, promo.action);
      },
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.fromMaterial(promo.categorySlug ?? promo.promoType), size: 14, color: c.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Overline(promo.highlightValue ?? promo.badge ?? 'Guide', color: c.accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(promo.title, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Expanded(
            child: Text(promo.summary, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  final HomeCollection collection;
  const _CollectionRow({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: collection.title,
          subtitle: collection.subtitle,
          actionLabel: collection.action.isNone ? null : (collection.action.label ?? 'See all'),
          onAction: collection.action.isNone ? null : () => openContentAction(context, collection.action),
          padding: const EdgeInsets.fromLTRB(0, AppDimensions.p24, 0, AppDimensions.p10),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: collection.cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _MiniCardTile(card: collection.cards[i]),
          ),
        ),
      ],
    );
  }
}

class _MiniCardTile extends StatelessWidget {
  final CatalogCard card;
  const _MiniCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressableScale(
      onTap: () => CardDetailScreen.open(context, slug: card.slug, card: card),
      child: SizedBox(
        width: 136,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardThumb(cardName: card.name, bankName: card.bankName, network: card.network, imageUrl: card.imageUrl, width: 136),
            const SizedBox(height: 8),
            Text(card.shortName, style: context.text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: Text(card.bankName, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(card.returnLabel, style: AppTypography.numeric(11, color: c.accent, weight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
