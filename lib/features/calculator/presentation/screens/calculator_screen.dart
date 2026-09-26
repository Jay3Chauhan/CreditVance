import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/animated_amount.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../catalog/presentation/widgets/card_picker_sheet.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/calculation_result.dart';
import '../providers/calculator_provider.dart';

const _bucketColors = {
  SpendBucket.dining: AppColors.rose,
  SpendBucket.travel: AppColors.sapphire,
  SpendBucket.grocery: AppColors.emerald,
  SpendBucket.shopping: AppColors.violet,
  SpendBucket.bills: AppColors.amber,
  SpendBucket.other: AppColors.teal,
};

IconData _bucketIcon(SpendBucket b) => AppIcons.forCategory(b.categorySlug);

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter(maxWidth: AppDimensions.wideContentMaxWidth);
    final wide = context.screenWidth - gutter * 2 >= 880;

    const summary = [
      _CardSelector(),
      SizedBox(height: AppDimensions.p12),
      _ResultHero(),
      SizedBox(height: AppDimensions.p12),
      _BreakdownCard(),
    ];
    const inputs = [
      _PresetStrip(),
      SizedBox(height: AppDimensions.p12),
      _SpendSliders(),
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            titleSpacing: gutter,
            toolbarHeight: 64,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.rewardsTitle, style: context.text.headlineMedium),
                Text(AppStrings.rewardsSubtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: wide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(children: summary)),
                        SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: inputs)),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [...summary, SizedBox(height: AppDimensions.p20), ...inputs],
                    ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: const SliverToBoxAdapter(child: _WalletShowdown()),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Estimates use each card\'s published base reward rate, with accelerated rates for popular cards. '
                'Actual rewards depend on merchant category, caps and point value.',
                style: context.text.bodySmall,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: context.navClearance)),
        ],
      ),
    );
  }
}

class _CardSelector extends StatelessWidget {
  const _CardSelector();

  Future<void> _pick(BuildContext context) async {
    final wallet = context.read<WalletProvider>().cards;
    final picked = await showCardPicker(context, title: 'Simulate a card', walletCards: wallet);
    if (picked == null || !context.mounted) return;
    final calc = context.read<CalculatorProvider>();
    if (picked.wallet != null) {
      calc.selectWalletCard(picked.wallet!);
    } else if (picked.catalog != null) {
      calc.selectCatalogCard(picked.catalog!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.select<CalculatorProvider, RewardSubject>((p) => p.subject);
    return AppSurface(
      onTap: () => _pick(context),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CardThumb(cardName: s.name, bankName: s.bankName, width: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(s.name, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (s.userCardId != null) ...[
                      const SizedBox(width: 6),
                      Icon(AppIcons.navWalletActive, size: 13, color: c.accent),
                    ],
                  ],
                ),
                Text(s.bankName, style: context.text.bodySmall),
              ],
            ),
          ),
          AppChip(label: 'Change', icon: AppIcons.sort, onTap: () => _pick(context)),
        ],
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = context.watch<CalculatorProvider>().result;
    final positive = r.netBenefit >= 0;

    return AppSurface(
      tone: SurfaceTone.accent,
      tintColor: positive ? c.success : c.danger,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net value per year', style: context.text.bodySmall),
          const SizedBox(height: 2),
          AnimatedAmount(value: r.netBenefit, style: AppTypography.numeric(32, color: positive ? c.success : c.danger)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Rewards earned', value: r.totalRewardValue)),
              Expanded(
                child: _MiniStat(
                  label: r.feeWaived ? 'Fee (waived)' : 'Annual fee',
                  value: r.annualFee,
                  negative: r.annualFee > 0,
                  badge: r.feeWaived,
                ),
              ),
              Expanded(child: _MiniStat(label: 'Effective return', value: r.effectiveRoi, isPercent: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final bool isPercent;
  final bool negative;
  final bool badge;

  const _MiniStat({required this.label, required this.value, this.isPercent = false, this.negative = false, this.badge = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(label, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (badge) ...[const SizedBox(width: 4), Icon(AppIcons.checkCircle, size: 11, color: c.success)],
          ],
        ),
        const SizedBox(height: 2),
        AnimatedAmount(
          value: value,
          isPercent: isPercent,
          compact: !isPercent,
          prefix: negative ? '−' : '',
          style: AppTypography.numeric(15, color: negative ? c.textSecondary : c.textPrimary),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = context.watch<CalculatorProvider>().result;
    final total = r.totalRewardValue;
    final parts = r.breakdowns.where((b) => b.earnedRupees > 0).toList();

    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    startDegreeOffset: -90,
                    sections: parts.isEmpty
                        ? [PieChartSectionData(value: 1, color: c.surfaceHigh, radius: 14, showTitle: false)]
                        : [
                            for (final b in parts)
                              PieChartSectionData(
                                value: b.earnedRupees,
                                color: _bucketColors[b.bucket],
                                radius: 14,
                                showTitle: false,
                              ),
                          ],
                  ),
                  duration: AppDimensions.slowAnim,
                  curve: Curves.easeOutCubic,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(CurrencyFormatter.compact(total), style: AppTypography.numeric(15, color: c.textPrimary)),
                    Text('earned', style: context.text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final b in r.breakdowns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: _bucketColors[b.bucket], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(b.bucket.label, style: context.text.bodySmall!.copyWith(color: c.textSecondary), maxLines: 1),
                        ),
                        Text(
                          CurrencyFormatter.formatPercentage(b.returnPercentage),
                          style: context.text.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Text(
                            CurrencyFormatter.compact(b.earnedRupees),
                            textAlign: TextAlign.right,
                            style: AppTypography.numeric(12, color: c.textPrimary, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetStrip extends StatelessWidget {
  const _PresetStrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Overline('Monthly spends'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in CalculatorProvider.presets.entries)
              AppChip(
                label: e.key,
                icon: AppIcons.lightbulb,
                onTap: () => context.read<CalculatorProvider>().applyPreset(e.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _SpendSliders extends StatelessWidget {
  const _SpendSliders();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final calc = context.watch<CalculatorProvider>();
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Total per month', style: context.text.bodySmall)),
              AnimatedAmount(value: calc.monthlyTotal, style: AppTypography.numeric(15, color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          for (final b in SpendBucket.values)
            _SliderRow(
              bucket: b,
              value: calc.monthlyFor(b),
              onChanged: (v) => context.read<CalculatorProvider>().setSpend(b, v),
            ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final SpendBucket bucket;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderRow({required this.bucket, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _bucketColors[bucket]!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_bucketIcon(bucket), size: 15, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(bucket.label, style: context.text.bodyMedium!.copyWith(color: c.textPrimary))),
              Text(CurrencyFormatter.format(value), style: AppTypography.numeric(13, color: c.textPrimary, weight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(0, CalculatorProvider.sliderMax),
              max: CalculatorProvider.sliderMax,
              divisions: 200,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletShowdown extends StatelessWidget {
  const _WalletShowdown();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final calc = context.watch<CalculatorProvider>();
    final results = calc.walletShowdown;
    if (results.length < 2) return const SizedBox.shrink();
    final top = results.first.netBenefit.abs();
    final maxAbs = results.map((r) => r.netBenefit.abs()).fold<double>(top, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Wallet showdown',
          subtitle: 'Your cards ranked on these spends',
          padding: EdgeInsets.fromLTRB(0, AppDimensions.p24, 0, AppDimensions.p10),
        ),
        AppSurface(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < results.length; i++)
                InkWell(
                  onTap: () {
                    final card = context.read<WalletProvider>().cards.firstWhere((w) => w.id == results[i].subject.userCardId);
                    context.read<CalculatorProvider>().selectWalletCard(card);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: i == 0
                              ? Icon(AppIcons.crown, size: 15, color: c.accent)
                              : Text('${i + 1}', style: context.text.labelMedium),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      results[i].subject.name,
                                      style: context.text.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(results[i].netBenefit),
                                    style: AppTypography.numeric(13, color: results[i].netBenefit >= 0 ? c.success : c.danger),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: AppDimensions.roundedFull,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: maxAbs == 0 ? 0 : (results[i].netBenefit.abs() / maxAbs)),
                                  duration: AppDimensions.slowAnim,
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, _) => LinearProgressIndicator(
                                    value: v,
                                    minHeight: 4,
                                    backgroundColor: c.surfaceHigh,
                                    color: i == 0 ? c.accent : c.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: AppDimensions.staggerStep * i),
            ],
          ),
        ),
      ],
    );
  }
}
