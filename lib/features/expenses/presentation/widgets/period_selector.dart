import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../domain/entities/spend_analytics.dart';
import '../providers/expense_provider.dart';

/// Horizontal chip row for the analytics window; rebuilds only on period change.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, AnalyticsPeriod>(
      selector: (_, p) => p.period,
      builder: (context, selected, _) {
        return SizedBox(
          height: AppDimensions.chipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AnalyticsPeriod.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.p8),
            itemBuilder: (context, i) {
              final period = AnalyticsPeriod.values[i];
              return _PeriodChip(
                label: period.label,
                isSelected: period == selected,
                onTap: () {
                  HapticsHelper.selection();
                  context.read<ExpenseProvider>().setPeriod(period);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimensions.fastAnim,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? c.accent : c.surfaceAlt,
          borderRadius: AppDimensions.roundedFull,
          border: Border.all(color: isSelected ? c.accent : c.border),
        ),
        child: Text(
          label,
          style: (context.text.labelLarge ?? AppTypography.labelLarge).copyWith(
            color: isSelected ? c.onAccent : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

