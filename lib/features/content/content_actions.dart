import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/app_toast.dart';
import '../../core/utils/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../advisor/presentation/providers/advisor_provider.dart';
import '../catalog/presentation/providers/catalog_provider.dart';
import '../catalog/presentation/screens/card_detail_screen.dart';
import '../catalog/presentation/screens/compare_screen.dart';
import '../remote_config/presentation/remote_config_controller.dart';
import '../shell/presentation/providers/navigation_provider.dart';
import 'data/content_repository.dart';
import 'domain/content_models.dart';
import 'presentation/screens/shortlist_screen.dart';

/// Routes a banner, promotion or quick-action tap.
void openContentAction(BuildContext context, ContentAction action) {
  if (action.type == 'none') return;
  final navigator = Navigator.of(context);
  final host = navigator.context;
  if (navigator.canPop()) navigator.popUntil((route) => route.isFirst);
  if (!host.mounted) return;
  _open(host, action);
}

Future<void> _open(BuildContext context, ContentAction action) async {
  final target = action.target;
  switch (action.type) {
    case 'screen':
      _openScreen(context, target);
    case 'card':
      if (target != null && target.isNotEmpty) {
        await CardDetailScreen.open(context, slug: target);
      }
    case 'category':
      if (target != null && target.isNotEmpty) {
        context.read<AdvisorProvider>().applyDeepLink(category: target);
        context.read<NavigationProvider>().setIndex(NavigationProvider.home);
      }
    case 'promotion':
      if (target != null && target.isNotEmpty) await _showPromotion(context, target);
    case 'url':
      if (target != null) await openExternalUrl(context, target);
    default:
      break;
  }
}

void _openScreen(BuildContext context, String? target) {
  final uri = Uri.parse(target ?? '/advisor');
  final path = uri.path;
  final nav = context.read<NavigationProvider>();
  final advisor = context.read<AdvisorProvider>();
  final catalog = context.read<CatalogProvider>();

  if (path.startsWith('/advisor')) {
    advisor.applyDeepLink(
      category: uri.queryParameters['category'],
      international: uri.queryParameters['international'] == 'true'
          ? true
          : uri.queryParameters['international'] == 'false'
              ? false
              : null,
    );
    nav.setIndex(NavigationProvider.home);
    return;
  }
  if (path.startsWith('/calculator')) {
    nav.setIndex(NavigationProvider.rewards);
    return;
  }
  if (path.startsWith('/wallet')) {
    nav.setIndex(NavigationProvider.wallet);
    return;
  }
  if (path.startsWith('/saved')) {
    ShortlistScreen.open(context);
    return;
  }
  if (path.startsWith('/compare')) {
    nav.setIndex(NavigationProvider.explore);
    if (!context.read<RemoteConfigController>().config.compareEnabled) {
      AppToast.info(context, message: 'Comparing cards is turned off right now');
      return;
    }
    if (catalog.compareList.length >= 2) {
      CompareScreen.open(context);
    } else {
      AppToast.info(context, message: 'Open any card and tap Compare to add it');
    }
    return;
  }
  if (path.startsWith('/catalog')) {
    catalog.applyRoute(
      feeType: uri.queryParameters['fee_type'],
      hasLounge: uri.queryParameters['has_lounge'] == 'true' ? true : null,
      sortBy: uri.queryParameters['sort_by'],
      network: uri.queryParameters['network'],
      bankSlug: uri.queryParameters['bank_slug'],
    );
    nav.setIndex(NavigationProvider.explore);
  }
}

Future<void> _showPromotion(BuildContext context, String slug) async {
  final result = await context.read<ContentRepository>().promotion(slug);
  if (!context.mounted) return;
  final promo = result.dataOrNull;
  if (promo == null) {
    AppToast.error(context, message: result.errorOrNull ?? 'Could not open that guide');
    return;
  }
  context.read<ContentRepository>().trackPromotion(promo.id, 'click');
  showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(promo.title, style: ctx.text.headlineSmall),
            const SizedBox(height: 8),
            Text(promo.description ?? promo.summary, style: ctx.text.bodyMedium),
            if (promo.terms != null && promo.terms!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(promo.terms!, style: ctx.text.bodySmall),
            ],
            if (!promo.action.isNone) ...[
              const SizedBox(height: 16),
              AppButton(
                label: promo.action.label ?? 'Open',
                onPressed: () {
                  Navigator.pop(ctx);
                  openContentAction(context, promo.action);
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
    if (context.mounted) AppToast.error(context, message: 'That link is not available');
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) AppToast.error(context, message: 'Could not open the link');
}
