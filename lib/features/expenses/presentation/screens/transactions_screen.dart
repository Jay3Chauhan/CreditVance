import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/spend_category.dart';
import '../../domain/entities/transaction_filter.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_visuals.dart';
import '../widgets/transaction_tile.dart';

/// Full transaction list with type / category / card / text filters.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  /// Opens the list, optionally pre-filtered (e.g. from a category row).
  static Future<void> open(BuildContext context, {TransactionFilter filter = TransactionFilter.none}) {
    HapticsHelper.light();
    context.read<ExpenseProvider>().setFilter(filter);
    return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TransactionsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(title: Text('Transactions', style: AppTypography.headlineLarge)),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: Selector<ExpenseProvider, List<CardTransaction>>(
              selector: (_, p) => p.filteredTransactions,
              builder: (context, txns, _) {
                if (txns.isEmpty) {
                  return const EmptyStateView(
                    title: 'No matching transactions',
                    message: 'Try a different filter or search term.',
                    icon: AppIcons.search,
                  );
                }
                return _GroupedTransactionList(transactions: txns);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, (TransactionFilter, List<String>)>(
      selector: (_, p) => (p.filter, p.knownCardLast4s),
      shouldRebuild: (a, b) => a.$1 != b.$1 || a.$2.join() != b.$2.join(),
      builder: (context, data, _) {
        final (filter, cards) = data;
        final provider = context.read<ExpenseProvider>();
        return Padding(
          padding: AppDimensions.screenHorizontal,
          child: Column(
            children: [
              TextField(
                onChanged: (q) => provider.setFilter(provider.filter.copyWith(query: q.trim())),
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                cursorColor: AppColors.gold,
                decoration: const InputDecoration(
                  hintText: 'Search merchant or bank',
                  prefixIcon: Icon(AppIcons.search, color: AppColors.textTertiary, size: AppDimensions.iconMd),
                ),
              ),
              const SizedBox(height: AppDimensions.p8),
              _ChipRow(
                children: [
                  for (final t in TransactionTypeFilter.values)
                    _FilterChip(
                      label: t.label,
                      selected: filter.type == t,
                      onTap: () => provider.setFilter(filter.copyWith(type: t)),
                    ),
                ],
              ),
              _ChipRow(
                children: [
                  _FilterChip(
                    label: 'All categories',
                    selected: filter.category == null,
                    onTap: () => provider.setFilter(filter.copyWith(clearCategory: true)),
                  ),
                  for (final c in SpendCategory.values)
                    _FilterChip(
                      label: c.label,
                      icon: c.icon,
                      iconColor: c.color,
                      selected: filter.category == c,
                      onTap: () => provider.setFilter(filter.copyWith(category: c)),
                    ),
                ],
              ),
              if (cards.length > 1)
                _ChipRow(
                  children: [
                    _FilterChip(
                      label: 'All cards',
                      selected: filter.cardLast4 == null,
                      onTap: () => provider.setFilter(filter.copyWith(clearCard: true)),
                    ),
                    for (final last4 in cards)
                      _FilterChip(
                        label: '•• $last4',
                        icon: AppIcons.navWallet,
                        selected: filter.cardLast4 == last4,
                        onTap: () => provider.setFilter(filter.copyWith(cardLast4: last4)),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> children;

  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p8),
      child: SizedBox(
        height: AppDimensions.chipHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.p8),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticsHelper.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppDimensions.fastAnim,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.surfaceSecondary,
          borderRadius: AppDimensions.roundedFull,
          border: Border.all(color: selected ? AppColors.gold : AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppDimensions.iconXs, color: selected ? AppColors.canvasDark : iconColor),
              const SizedBox(width: AppDimensions.p4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: selected ? AppColors.canvasDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Day-grouped list with per-day net spend headers.
class _GroupedTransactionList extends StatelessWidget {
  final List<CardTransaction> transactions;

  const _GroupedTransactionList({required this.transactions});

  static final DateFormat _dayFormat = DateFormat('EEE, d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final rows = <Object>[];
    DateTime? currentDay;
    for (final t in transactions) {
      final day = DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day);
      if (currentDay != day) {
        currentDay = day;
        rows.add(day);
      }
      rows.add(t);
    }

    double netFor(DateTime day) => transactions
        .where((t) =>
            !t.isInternational &&
            t.occurredAt.year == day.year &&
            t.occurredAt.month == day.month &&
            t.occurredAt.day == day.day)
        .fold<double>(0, (a, t) => a + t.signedSpend);

    return ListView.builder(
      padding: AppDimensions.screenPadding,
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row is DateTime) {
          return Padding(
            padding: const EdgeInsets.only(top: AppDimensions.p12, bottom: AppDimensions.p4),
            child: Row(
              children: [
                Expanded(child: Text(_dayFormat.format(row), style: AppTypography.labelLarge)),
                Text(CurrencyFormatter.format(netFor(row)), style: AppTypography.labelSmall),
              ],
            ),
          );
        }
        return TransactionTile(transaction: row as CardTransaction);
      },
    );
  }
}
