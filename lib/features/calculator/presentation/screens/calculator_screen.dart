import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
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
import '../../../../core/widgets/state_views.dart';
import '../../../remote_config/presentation/remote_config_controller.dart';
import '../../../catalog/presentation/widgets/card_picker_sheet.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/calculation_result.dart';
import '../providers/calculator_provider.dart';

IconData _bucketIcon(SpendBucket b) => AppIcons.forCategory(b.categorySlug);

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<RemoteConfigController, bool>((c) => c.config.calculatorEnabled);
    if (!enabled) {
      return Padding(
        padding: EdgeInsets.only(bottom: context.navClearance),
        child: const EmptyStateView(
          icon: AppIcons.calculator,
          title: 'Rewards calculator is paused',
          message: 'This tool is temporarily unavailable. Your cards and saved spends are unchanged.',
        ),
      );
    }
    final gutter = context.gutter(maxWidth: AppDimensions.wideContentMaxWidth);
    final wide = context.screenWidth - gutter * 2 >= 880;

    const summary = [
      _CardSelector(),
      SizedBox(height: AppDimensions.p12),
      _ResultHero(),
      SizedBox(height: AppDimensions.p12),
      _BreakEvenChart(),
      SizedBox(height: AppDimensions.p12),
      _BreakdownChart(),
    ];
    const inputs = [
      _PresetStrip(),
      SizedBox(height: AppDimensions.p10),
      _SpendSliders(),
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
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
    final calc = context.watch<CalculatorProvider>();
    final r = calc.result;
    final positive = r.netBenefit >= 0;
    final fee = r.feeWaived ? 0.0 : r.annualFee;
    final total = r.totalRewardValue + fee;

    return AppSurface(
      elevated: true,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.tint(c.accent, c.isDark ? 0.16 : 0.12), c.surface],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('You keep every year', style: context.text.bodySmall)),
              if (r.feeWaived) AppTag(label: 'Fee waived', icon: AppIcons.checkCircle, color: c.success),
            ],
          ),
          const SizedBox(height: 2),
          AnimatedAmount(value: r.netBenefit, style: AppTypography.numeric(34, color: positive ? c.textPrimary : c.danger)),
          Text(
            'On ${CurrencyFormatter.compact(calc.monthlyTotal)} a month · ${CurrencyFormatter.formatPercentage(r.effectiveRoi)} effective return',
            style: context.text.labelSmall,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: AppDimensions.roundedFull,
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? ColoredBox(color: c.surfaceHigh)
                  : Row(
                      children: [
                        Expanded(
                          flex: math.max(1, (r.totalRewardValue / total * 1000).round()),
                          child: ColoredBox(color: c.accent),
                        ),
                        if (fee > 0) ...[
                          const SizedBox(width: 2),
                          Expanded(
                            flex: math.max(1, (fee / total * 1000).round()),
                            child: ColoredBox(color: c.borderStrong),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Legend(color: c.accent, label: 'Rewards', value: r.totalRewardValue)),
              Expanded(
                child: _Legend(
                  color: c.borderStrong,
                  label: r.feeWaived ? 'Fee (waived)' : 'Annual fee',
                  value: fee,
                  negative: fee > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  final bool negative;
  const _Legend({required this.color, required this.label, required this.value, this.negative = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        AnimatedAmount(
          value: value,
          compact: true,
          prefix: negative ? '−' : '',
          style: AppTypography.numeric(12.5, color: c.textPrimary, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

double _niceStep(double raw) {
  if (raw <= 0) return 1;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final n = raw / magnitude;
  final nice = n <= 1 ? 1 : (n <= 2 ? 2 : (n <= 5 ? 5 : 10));
  return nice * magnitude;
}

/// Cumulative net value across the first year, fee charged up front.
class _BreakEvenChart extends StatelessWidget {
  const _BreakEvenChart();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = context.watch<CalculatorProvider>().result;
    final fee = r.feeWaived ? 0.0 : r.annualFee;
    final monthly = r.totalRewardValue / 12;
    final points = [for (var m = 0; m <= 12; m++) FlSpot(m.toDouble(), m * monthly - fee)];
    final breakEven = fee == 0 ? 0 : (monthly <= 0 ? null : (fee / monthly).ceil());

    final String headline;
    if (breakEven == 0) {
      headline = 'In profit from the first swipe';
    } else if (breakEven != null && breakEven <= 12) {
      headline = 'Pays for its fee in month $breakEven';
    } else {
      headline = 'Doesn\'t cover its fee this year';
    }

    final minY = math.min(0.0, points.first.y);
    final maxY = math.max(points.last.y, 1.0);
    final pad = (maxY - minY) * 0.12;
    final interval = _niceStep((maxY - minY) / 3);

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.trendUp, size: 15, color: c.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(headline, style: context.text.titleSmall)),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Text('Running total over 12 months', style: context.text.labelSmall),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 12,
                minY: minY - pad,
                maxY: maxY + pad,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (fee > 0) HorizontalLine(y: 0, color: c.borderStrong, strokeWidth: 1, dashArray: [4, 4]),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: interval,
                      getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                          ? const SizedBox.shrink()
                          : SideTitleWidget(
                              meta: meta,
                              child: Text(CurrencyFormatter.compact(v), style: context.text.labelSmall),
                            ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(v == 0 ? 'Now' : 'M${v.toInt()}', style: context.text.labelSmall),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => c.surfaceHigh,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${s.x == 0 ? 'Start' : 'Month ${s.x.toInt()}'}\n',
                          context.text.labelSmall!,
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.format(s.y),
                              style: AppTypography.numeric(12.5, color: c.textPrimary, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: false,
                    color: c.accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      checkToShowDot: (spot, _) => breakEven != null && breakEven > 0 && spot.x == breakEven.toDouble(),
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: c.accent,
                        strokeWidth: 2,
                        strokeColor: c.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.tint(c.accent, 0.28), c.tint(c.accent, 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
              duration: AppDimensions.mediumAnim,
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rewards earned per spend category, one hue with the leader highlighted.
class _BreakdownChart extends StatelessWidget {
  const _BreakdownChart();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = context.watch<CalculatorProvider>().result;
    final rows = r.breakdowns;
    final top = rows.fold<double>(0, (m, b) => math.max(m, b.earnedRupees));
    final ceiling = top == 0 ? 1.0 : top * 1.15;

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.chartBar, size: 15, color: c.accent),
              const SizedBox(width: 8),
              Expanded(child: Text('Where rewards come from', style: context.text.titleSmall)),
              Text('per year', style: context.text.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: ceiling,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                        final lead = rows[i].earnedRupees == top && top > 0;
                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Icon(_bucketIcon(rows[i].bucket), size: 15, color: lead ? c.accent : c.textTertiary),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => c.surfaceHigh,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${rows[group.x].bucket.label}\n',
                      context.text.labelSmall!,
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(rod.toY),
                          style: AppTypography.numeric(12.5, color: c.textPrimary, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < rows.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rows[i].earnedRupees,
                          width: 18,
                          color: rows[i].earnedRupees == top && top > 0 ? c.accent : c.tint(c.accent, 0.42),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                ],
              ),
              duration: AppDimensions.mediumAnim,
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 10),
          for (final b in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(_bucketIcon(b.bucket), size: 14, color: c.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b.bucket.label, style: context.text.bodySmall!.copyWith(color: c.textSecondary))),
                  Text(CurrencyFormatter.formatPercentage(b.returnPercentage), style: context.text.labelSmall),
                  SizedBox(
                    width: 64,
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
        const SectionHeader(
          title: 'Your monthly spends',
          subtitle: 'Start from a profile, then fine-tune',
          padding: EdgeInsets.fromLTRB(0, AppDimensions.p8, 0, AppDimensions.p10),
        ),
        ChipStrip(
          padding: EdgeInsets.zero,
          children: [
            for (final e in CalculatorProvider.presets.entries)
              AppChip(
                label: e.key,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total per month', style: context.text.labelSmall),
                    AnimatedAmount(value: calc.monthlyTotal, style: AppTypography.numeric(15, color: c.textPrimary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Net per year', style: context.text.labelSmall),
                  AnimatedAmount(
                    value: calc.result.netBenefit,
                    style: AppTypography.numeric(15, color: calc.result.netBenefit >= 0 ? c.accent : c.danger),
                  ),
                ],
              ),
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
    final color = c.accent;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_bucketIcon(bucket), size: 15, color: value > 0 ? color : c.textTertiary),
              const SizedBox(width: 8),
              Expanded(child: Text(bucket.label, style: context.text.bodyMedium!.copyWith(color: c.textPrimary))),
              Text(CurrencyFormatter.format(value), style: AppTypography.numeric(13, color: c.textPrimary, weight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: c.surfaceHigh,
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
