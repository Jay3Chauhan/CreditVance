import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../advisor/presentation/providers/advisor_provider.dart';
import '../../../shell/presentation/providers/navigation_provider.dart';
import '../../../wallet/domain/entities/user_card.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/content_models.dart';
import '../providers/home_provider.dart';
import 'home_feed.dart';

/// Whole-wallet summary shown under the focused card. Fees and due dates are
/// computed on device; category picks come from `/wallet/insights` when
/// signed in.
class WalletOverview extends StatelessWidget {
  const WalletOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.select<WalletProvider, List<UserCard>>((w) => w.cards);
    if (cards.isEmpty) return const SizedBox.shrink();
    final insights = context.select<HomeProvider, WalletInsights?>((h) => h.walletInsights);
    final banners = context
        .select<HomeProvider, List<AppBanner>>((h) => h.bannersFor('wallet'))
        .where((b) => !(b.action.target ?? '').startsWith('/wallet'))
        .toList();

    final yearlyFees = insights?.totalRenewalFee ?? cards.fold<double>(0, (sum, c) => sum + c.annualFee);
    UserCard? nextDueCard;
    for (final card in cards) {
      final due = card.estimatedDueDate;
      if (due == null) continue;
      if (nextDueCard == null || due.isBefore(nextDueCard.estimatedDueDate!)) nextDueCard = card;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gutter()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Wallet overview',
            padding: EdgeInsets.fromLTRB(0, AppDimensions.p24, 0, AppDimensions.p10),
          ),
          AppSurface(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _Metric(
                    icon: AppIcons.receipt,
                    label: 'Yearly fees',
                    value: yearlyFees == 0 ? 'Free' : CurrencyFormatter.compact(yearlyFees),
                  ),
                  const _Divider(),
                  _Metric(
                    icon: AppIcons.bell,
                    label: nextDueCard == null ? 'Next due' : 'Due · ${nextDueCard.last4Digits}',
                    value: nextDueCard == null ? 'Add date' : DateFormat('d MMM').format(nextDueCard.estimatedDueDate!),
                  ),
                  const _Divider(),
                  insights != null
                      ? _Metric(icon: AppIcons.lounge, label: 'Lounge cards', value: '${insights.loungeCardCount}')
                      : _Metric(icon: AppIcons.cardholder, label: 'Cards', value: '${cards.length}'),
                ],
              ),
            ),
          ),
          if (insights != null && insights.categoryPicks.isNotEmpty) ...[
            const SectionHeader(
              title: 'Best card you hold for',
              padding: EdgeInsets.fromLTRB(0, AppDimensions.p20, 0, AppDimensions.p10),
            ),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: insights.categoryPicks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _PickTile(pick: insights.categoryPicks[i]),
              ),
            ),
          ],
          if (banners.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.p16),
            PromoBanner(banner: banners.first, compact: true),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: c.textTertiary),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.numeric(15, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => VerticalDivider(width: 1, thickness: 1, color: context.colors.border);
}

class _PickTile extends StatelessWidget {
  final CategoryPick pick;
  const _PickTile({required this.pick});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rate = pick.ratePercent;
    return AppSurface(
      onTap: () {
        context.read<AdvisorProvider>().applyDeepLink(category: pick.categorySlug);
        context.read<NavigationProvider>().setIndex(NavigationProvider.home);
      },
      padding: const EdgeInsets.all(10),
      borderRadius: AppDimensions.roundedMd,
      child: SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.fromMaterial(pick.iconKey ?? pick.categorySlug), size: 14, color: c.accent),
                const Spacer(),
                Text(
                  '${rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 1)}%',
                  style: AppTypography.numeric(13, color: c.accent),
                ),
              ],
            ),
            const Spacer(),
            Text(pick.categorySlug, style: context.text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(pick.nickname ?? 'Your card', style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
