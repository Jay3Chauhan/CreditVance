import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

/// Bottom sheet with transaction details, category correction and exclusion.
class TransactionDetailsSheet extends StatelessWidget {
  final CardTransaction transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  /// Presents the sheet for [transaction].
  static Future<void> show(BuildContext context, CardTransaction transaction) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider<ExpenseProvider>.value(
        value: context.read<ExpenseProvider>(),
        child: TransactionDetailsSheet(transaction: transaction),
      ),
    );
  }

  static final DateFormat _dateFormat = DateFormat('EEE, d MMM yyyy • h:mm a');

  String get _sourceLabel => switch (transaction.source) {
        TransactionSource.sms => 'Parsed on this device from a bank SMS',
        TransactionSource.pastedSms => 'Parsed on this device from a pasted SMS',
        TransactionSource.manual => 'Added manually',
        TransactionSource.server => 'Restored from your Credvert backup',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = transaction;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimensions.p20, AppDimensions.p16, AppDimensions.p20, AppDimensions.p24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppDimensions.p40,
                  height: AppDimensions.p4,
                  decoration: BoxDecoration(color: c.borderStrong, borderRadius: AppDimensions.roundedFull),
                ),
              ),
              const SizedBox(height: AppDimensions.p16),
              Text(t.merchantName, style: context.text.headlineLarge ?? AppTypography.headlineLarge),
              const SizedBox(height: AppDimensions.p4),
              Text(
                CurrencyFormatter.formatWithCode(t.amount, t.currency, showDecimals: true),
                style: AppTypography.numeric(20, color: c.textPrimary),
              ),
              const SizedBox(height: AppDimensions.p12),
              Wrap(
                spacing: AppDimensions.p8,
                runSpacing: AppDimensions.p8,
                children: [
                  LuxuryBadge(label: t.type.name.toUpperCase(), isSmall: true),
                  LuxuryBadge(
                    label: t.cardLast4 == null ? t.bankName : '${t.bankName} •• ${t.cardLast4}',
                    icon: AppIcons.navWallet,
                    isSmall: true,
                  ),
                  if (t.channel == TransactionChannel.upi)
                    const LuxuryBadge(label: 'UPI', icon: AppIcons.upi, variant: LuxuryBadgeVariant.sapphire, isSmall: true),
                  if (t.needsReview)
                    LuxuryBadge(
                      label: 'Review • ${(t.confidence * 100).round()}% confident',
                      icon: AppIcons.review,
                      variant: LuxuryBadgeVariant.gold,
                      isSmall: true,
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.p16),
              _DetailRow(label: 'When', value: _dateFormat.format(t.occurredAt)),
              if (t.merchantRaw.isNotEmpty && t.merchantRaw != t.merchantName)
                _DetailRow(label: 'As shown by bank', value: t.merchantRaw),
              if (t.availableLimit != null)
                _DetailRow(label: 'Available limit', value: CurrencyFormatter.format(t.availableLimit!)),
              _DetailRow(label: 'Source', value: _sourceLabel),
              const SizedBox(height: AppDimensions.p16),
              Text('Category', style: AppTypography.titleSmall),
              const SizedBox(height: AppDimensions.p8),
              Wrap(
                spacing: AppDimensions.p8,
                runSpacing: AppDimensions.p8,
                children: [
                  for (final c in SpendCategory.values)
                    _CategoryChip(
                      category: c,
                      isSelected: c == t.category,
                      onTap: () async {
                        HapticsHelper.selection();
                        final provider = context.read<ExpenseProvider>();
                        Navigator.of(context).pop();
                        await provider.recategorize(t.id, c);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.p24),
              LuxuryButton(
                label: 'Not a transaction — remove',
                icon: AppIcons.hide,
                variant: LuxuryButtonVariant.danger,
                height: AppDimensions.buttonHeightSm,
                onPressed: () async {
                  final provider = context.read<ExpenseProvider>();
                  Navigator.of(context).pop();
                  await provider.excludeTransaction(t.id);
                  if (context.mounted) {
                    AppToast.info(context, title: 'Removed', message: 'This SMS will be ignored in future scans.');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: AppDimensions.p40 * 3, child: Text(label, style: context.text.bodyMedium ?? AppTypography.bodyMedium)),
          Expanded(child: Text(value, style: (context.text.bodyMedium ?? AppTypography.bodyMedium).copyWith(color: context.colors.textPrimary))),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final SpendCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: AnimatedContainer(
        duration: AppDimensions.fastAnim,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12, vertical: AppDimensions.p8),
        decoration: BoxDecoration(
          color: isSelected ? category.color.withValues(alpha: 0.2) : c.surfaceAlt,
          borderRadius: AppDimensions.roundedFull,
          border: Border.all(color: isSelected ? category.color : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: AppDimensions.iconXs, color: category.color),
            const SizedBox(width: AppDimensions.p4),
            Text(category.label, style: (context.text.labelSmall ?? AppTypography.labelSmall).copyWith(color: c.textPrimary)),
          ],
        ),
      ),
    );
  }
}
