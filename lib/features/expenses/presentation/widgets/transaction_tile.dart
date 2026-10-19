import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/spend_category.dart';
import '../providers/expense_provider.dart';
import 'category_visuals.dart';
import 'insights_section.dart';

/// One transaction row. Tap opens details with recategorise / exclude actions.
class TransactionTile extends StatelessWidget {
  final CardTransaction transaction;

  const TransactionTile({super.key, required this.transaction});

  static final DateFormat _dateFormat = DateFormat('d MMM, h:mm a');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = transaction;
    final isCredit = t.signedSpend < 0 || t.type == TransactionType.payment || t.type == TransactionType.credit;
    final amountText =
        '${isCredit ? '+' : ''}${CurrencyFormatter.formatWithCode(t.amount, t.currency, showDecimals: true)}';

    return InkWell(
      borderRadius: AppDimensions.roundedMd,
      onTap: () {
        HapticsHelper.selection();
        TransactionDetailsSheet.show(context, t);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.p8),
        child: Row(
          children: [
            CategoryIconTile(icon: _iconFor(t), color: _colorFor(t)),
            const SizedBox(width: AppDimensions.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.merchantName,
                          style: context.text.titleMedium ?? AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (t.needsReview) ...[
                        const SizedBox(width: AppDimensions.p4),
                        Icon(AppIcons.review, size: AppDimensions.iconXs, color: c.warning),
                      ],
                    ],
                  ),
                  Text(
                    '${_dateFormat.format(t.occurredAt)} • ${t.bankName}${t.cardLast4 == null ? '' : ' •• ${t.cardLast4}'}',
                    style: context.text.bodySmall ?? AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.p8),
            Text(
              amountText,
              style: (context.text.titleMedium ?? AppTypography.titleMedium).copyWith(
                color: isCredit ? c.success : c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(CardTransaction t) => switch (t.type) {
        TransactionType.refund || TransactionType.reversal => AppIcons.refund,
        TransactionType.payment => AppIcons.payment,
        TransactionType.credit => AppIcons.cashback,
        TransactionType.debit => t.channel == TransactionChannel.upi && t.category == SpendCategory.other
            ? AppIcons.upi
            : t.category.icon,
      };

  static Color _colorFor(CardTransaction t) => switch (t.type) {
        TransactionType.refund || TransactionType.reversal || TransactionType.credit => AppColors.emerald,
        TransactionType.payment => AppColors.sapphire,
        TransactionType.debit => t.category.color,
      };
}

/// Bottom sheet with full parsed details and correction actions.
class TransactionDetailsSheet extends StatelessWidget {
  final CardTransaction transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  /// Presents the sheet for [transaction].
  static Future<void> show(BuildContext context, CardTransaction transaction) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  static final DateFormat _dateFormat = DateFormat('EEE, d MMM yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = transaction;
    final provider = context.read<ExpenseProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIconTile(icon: t.category.icon, color: t.category.color, size: AppDimensions.avatarMd),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.merchantName, style: context.text.headlineMedium ?? AppTypography.headlineMedium),
                      Text(_dateFormat.format(t.occurredAt), style: context.text.bodySmall ?? AppTypography.bodySmall),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatWithCode(t.amount, t.currency, showDecimals: true),
                  style: AppTypography.numeric(20, color: c.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.p16),
            Wrap(
              spacing: AppDimensions.p8,
              runSpacing: AppDimensions.p8,
              children: [
                LuxuryBadge(label: t.type.name.toUpperCase(), variant: LuxuryBadgeVariant.gold, isSmall: true),
                LuxuryBadge(
                  label: t.cardLast4 == null ? t.bankName : '${t.bankName} •• ${t.cardLast4}',
                  icon: AppIcons.navWallet,
                  isSmall: true,
                ),
                if (t.channel == TransactionChannel.upi)
                  const LuxuryBadge(label: 'UPI', icon: AppIcons.upi, variant: LuxuryBadgeVariant.sapphire, isSmall: true),
                LuxuryBadge(
                  label: switch (t.source) {
                    TransactionSource.sms => 'From SMS',
                    TransactionSource.pastedSms => 'Pasted SMS',
                    TransactionSource.manual => 'Manual',
                    TransactionSource.server => 'Restored',
                  },
                  icon: AppIcons.sms,
                  isSmall: true,
                ),
                LuxuryBadge(
                  label: t.isSynced ? 'Backed up' : 'On device only',
                  icon: t.isSynced ? AppIcons.cloudDone : AppIcons.lock,
                  variant: t.isSynced ? LuxuryBadgeVariant.emerald : LuxuryBadgeVariant.neutral,
                  isSmall: true,
                ),
                if (t.needsReview)
                  LuxuryBadge(
                    label: 'Confidence ${(t.confidence * 100).round()}% — please review',
                    icon: AppIcons.review,
                    variant: LuxuryBadgeVariant.danger,
                    isSmall: true,
                  ),
              ],
            ),
            if (t.availableLimit != null) ...[
              const SizedBox(height: AppDimensions.p12),
              Text(
                'Available limit after this spend: ${CurrencyFormatter.format(t.availableLimit!, showDecimals: true)}',
                style: context.text.bodyMedium ?? AppTypography.bodyMedium,
              ),
            ],
            const SizedBox(height: AppDimensions.p20),
            Text('Category', style: context.text.titleSmall ?? AppTypography.titleSmall),
            const SizedBox(height: AppDimensions.p8),
            Wrap(
              spacing: AppDimensions.p8,
              runSpacing: AppDimensions.p8,
              children: [
                for (final cat in SpendCategory.values)
                  ChoiceChip(
                    label: Text(cat.label),
                    avatar: Icon(cat.icon, size: AppDimensions.iconSm, color: cat.color),
                    selected: cat == t.category,
                    labelStyle: (context.text.labelSmall ?? AppTypography.labelSmall).copyWith(
                      color: cat == t.category ? c.onAccent : c.textSecondary,
                    ),
                    selectedColor: c.accent,
                    backgroundColor: c.surfaceAlt,
                    side: BorderSide(color: c.border),
                    onSelected: (_) async {
                      HapticsHelper.selection();
                      await provider.recategorize(t.id, cat);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.p20),
            LuxuryButton(
              label: 'Not a card transaction — hide it',
              icon: AppIcons.hide,
              variant: LuxuryButtonVariant.danger,
              height: AppDimensions.buttonHeightSm,
              onPressed: () async {
                await provider.excludeTransaction(t.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                AppToast.info(context, title: 'Hidden', message: 'This record will not be imported again.');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact card listing the latest transactions with a "View all" action.
class RecentTransactionsCard extends StatelessWidget {
  final List<CardTransaction> transactions;
  final VoidCallback onViewAll;
  final int index;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.onViewAll,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InsightsSection(
      title: 'Recent transactions',
      icon: AppIcons.list,
      accent: context.colors.textSecondary,
      index: index,
      trailing: TextButton(onPressed: onViewAll, child: const Text('View all')),
      child: Column(children: [for (final t in transactions) TransactionTile(transaction: t)]),
    );
  }
}
