import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/spend_analytics.dart';
import 'insights_section.dart';

/// Six-month net spend bar chart (custom painted with layout widgets — no chart dependency).
class MonthlyTrendCard extends StatelessWidget {
  final List<MonthlySpend> months;
  final int index;

  const MonthlyTrendCard({super.key, required this.months, this.index = 0});

  static final DateFormat _monthFormat = DateFormat('MMM');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxAmount = months.fold<double>(0, (a, m) => m.amount > a ? m.amount : a);
    final average = months.isEmpty ? 0.0 : months.fold<double>(0, (a, m) => a + m.amount) / months.length;

    return InsightsSection(
      title: 'Monthly trend',
      subtitle: 'Avg ${CurrencyFormatter.format(average)} / month',
      icon: AppIcons.insights,
      accent: c.info,
      index: index,
      child: SizedBox(
        height: AppDimensions.chartHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < months.length; i++)
              Expanded(
                child: _Bar(
                  label: _monthFormat.format(months[i].month),
                  amount: months[i].amount,
                  fraction: maxAmount <= 0 ? 0 : (months[i].amount / maxAmount).clamp(0.0, 1.0),
                  isLatest: i == months.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double amount;
  final double fraction;
  final bool isLatest;

  const _Bar({required this.label, required this.amount, required this.fraction, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            amount > 0 ? CurrencyFormatter.formatCompact(amount) : '—',
            style: (context.text.labelSmall ?? AppTypography.labelSmall).copyWith(
              color: isLatest ? (c.isDark ? AppColors.goldLight : c.accent) : c.textTertiary,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: AppDimensions.p4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: fraction),
                duration: AppDimensions.slowAnim,
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  heightFactor: value < 0.02 ? 0.02 : value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isLatest
                          ? (c.isDark
                              ? AppColors.goldGradient
                              : LinearGradient(colors: [c.accent, c.accent.withValues(alpha: 0.75)]))
                          : (c.isDark
                              ? AppColors.sapphireGradient
                              : LinearGradient(colors: [c.info, c.info.withValues(alpha: 0.75)])),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.barRadius)),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.p4),
          Text(label, style: context.text.labelSmall ?? AppTypography.labelSmall),
        ],
      ),
    );
  }
}
