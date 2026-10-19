import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/luxury_text_field.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/sms_parse_result.dart';
import '../../domain/entities/spend_category.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_visuals.dart';
import '../widgets/reject_reason_labels.dart';

enum _EntryMode { paste, manual }

/// Route-scoped form state (controllers + micro-state notifiers), disposed with the route.
class _AddTransactionForm {
  final mode = ValueNotifier<_EntryMode>(_EntryMode.paste);
  final pasteController = TextEditingController();
  final preview = ValueNotifier<SmsParseOutcome?>(null);
  final amountController = TextEditingController();
  final merchantController = TextEditingController();
  final category = ValueNotifier<SpendCategory>(SpendCategory.shopping);
  final type = ValueNotifier<TransactionType>(TransactionType.debit);
  final cardId = ValueNotifier<int?>(null);
  final date = ValueNotifier<DateTime>(DateTime.now());
  final isSaving = ValueNotifier<bool>(false);

  /// Releases all controllers and notifiers.
  void dispose() {
    mode.dispose();
    pasteController.dispose();
    preview.dispose();
    amountController.dispose();
    merchantController.dispose();
    category.dispose();
    type.dispose();
    cardId.dispose();
    date.dispose();
    isSaving.dispose();
  }
}

/// Manual entry and "paste a bank SMS" import — the iOS fallback, and the
/// path for Android users who decline SMS access. Parsing is on-device.
class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  /// Pushes the screen with its scoped form state.
  static Future<void> open(BuildContext context) {
    HapticsHelper.light();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Provider<_AddTransactionForm>(
          create: (_) => _AddTransactionForm(),
          dispose: (_, form) => form.dispose(),
          child: const AddTransactionScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final form = context.read<_AddTransactionForm>();
    return Scaffold(
      appBar: AppBar(title: Text('Add a spend', style: AppTypography.headlineLarge.copyWith(color: c.textPrimary))),
      body: SafeArea(
        child: ListView(
          padding: AppDimensions.screenPadding,
          children: [
            ValueListenableBuilder<_EntryMode>(
              valueListenable: form.mode,
              builder: (context, mode, _) => SegmentedButton<_EntryMode>(
                segments: const [
                  ButtonSegment(value: _EntryMode.paste, label: Text('Paste bank SMS'), icon: Icon(AppIcons.paste)),
                  ButtonSegment(value: _EntryMode.manual, label: Text('Manual'), icon: Icon(AppIcons.edit)),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  HapticsHelper.selection();
                  form.mode.value = s.first;
                },
              ),
            ),
            const SizedBox(height: AppDimensions.p20),
            ValueListenableBuilder<_EntryMode>(
              valueListenable: form.mode,
              builder: (context, mode, _) =>
                  mode == _EntryMode.paste ? const _PasteSmsForm() : const _ManualEntryForm(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasteSmsForm extends StatelessWidget {
  const _PasteSmsForm();

  void _updatePreview(BuildContext context, String text) {
    final form = context.read<_AddTransactionForm>();
    form.preview.value =
        text.trim().length < 20 ? null : context.read<ExpenseProvider>().previewPastedSms(text);
  }

  @override
  Widget build(BuildContext context) {
    final form = context.read<_AddTransactionForm>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Long-press a bank SMS → Copy, then paste it here. It is parsed on this device; the text is not saved.',
          style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.p12),
        LuxuryTextField(
          controller: form.pasteController,
          hint: 'e.g. Spent Rs.1,234.00 On HDFC Bank Card 1234 At AMAZON On …',
          maxLines: 6,
          onChanged: (t) => _updatePreview(context, t),
        ),
        const SizedBox(height: AppDimensions.p8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(AppIcons.paste, size: AppDimensions.iconSm),
            label: const Text('Paste from clipboard'),
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final text = data?.text ?? '';
              if (!context.mounted) return;
              form.pasteController.text = text;
              _updatePreview(context, text);
            },
          ),
        ),
        ValueListenableBuilder<SmsParseOutcome?>(
          valueListenable: form.preview,
          builder: (context, outcome, _) => outcome == null ? const SizedBox.shrink() : _PreviewCard(outcome: outcome),
        ),
        const SizedBox(height: AppDimensions.p20),
        ValueListenableBuilder<SmsParseOutcome?>(
          valueListenable: form.preview,
          builder: (context, outcome, _) => ValueListenableBuilder<bool>(
            valueListenable: form.isSaving,
            builder: (context, saving, _) => LuxuryButton(
              label: 'Save',
              icon: AppIcons.check,
              isLoading: saving,
              onPressed: outcome == null || outcome is RejectedSms ? null : () => _save(context),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final form = context.read<_AddTransactionForm>();
    form.isSaving.value = true;
    final (outcome, error) = await context.read<ExpenseProvider>().importPastedSms(form.pasteController.text);
    form.isSaving.value = false;
    if (!context.mounted) return;
    if (error != null || outcome == null || outcome is RejectedSms) {
      AppToast.error(context, title: 'Not saved', message: error ?? 'This SMS is not a card transaction.');
      return;
    }
    AppToast.success(
      context,
      title: 'Saved',
      message: outcome is ParsedBillNotice ? 'Bill reminder added.' : 'Transaction added.',
    );
    Navigator.of(context).pop();
  }
}

class _PreviewCard extends StatelessWidget {
  final SmsParseOutcome outcome;

  const _PreviewCard({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (IconData icon, Color color, String title, List<String> lines) = switch (outcome) {
      ParsedTransaction(:final transaction) => (
          AppIcons.check,
          c.success,
          '${transaction.type.name.toUpperCase()} • '
              '${CurrencyFormatter.formatWithCode(transaction.amount, transaction.currency, showDecimals: true)}',
          [
            'Merchant: ${transaction.merchantName} (${transaction.category.label})',
            'Card: ${transaction.bankName}${transaction.cardLast4 == null ? '' : ' •• ${transaction.cardLast4}'}',
            'When: ${DateFormat('d MMM yyyy, h:mm a').format(transaction.occurredAt)}',
            'Confidence: ${(transaction.confidence * 100).round()}%',
          ],
        ),
      ParsedBillNotice(:final notice) => (
          AppIcons.receipt,
          c.warning,
          'Bill notice • ${notice.bankName}',
          [
            if (notice.totalDue != null) 'Total due: ${CurrencyFormatter.format(notice.totalDue!, showDecimals: true)}',
            if (notice.minimumDue != null)
              'Minimum due: ${CurrencyFormatter.format(notice.minimumDue!, showDecimals: true)}',
            if (notice.dueDate != null) 'Due: ${DateFormat('d MMM yyyy').format(notice.dueDate!)}',
          ],
        ),
      RejectedSms(:final reason) => (AppIcons.alertCircle, c.danger, 'Not a card transaction', [reason.label]),
    };

    return LuxuryGlassCard(
      border: Border.all(color: color.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppDimensions.iconMd),
              const SizedBox(width: AppDimensions.p8),
              Expanded(child: Text(title, style: AppTypography.titleMedium.copyWith(color: c.textPrimary))),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          for (final line in lines) Text(line, style: AppTypography.bodyMedium.copyWith(color: c.textSecondary)),
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.fastAnim);
  }
}

class _ManualEntryForm extends StatelessWidget {
  const _ManualEntryForm();

  static final DateFormat _dateFormat = DateFormat('EEE, d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final form = context.read<_AddTransactionForm>();
    final cards = context.read<ExpenseProvider>().cards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<TransactionType>(
          valueListenable: form.type,
          builder: (context, type, _) => SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.debit, label: Text('Spend')),
              ButtonSegment(value: TransactionType.refund, label: Text('Refund')),
            ],
            selected: {type},
            showSelectedIcon: false,
            onSelectionChanged: (s) => form.type.value = s.first,
          ),
        ),
        const SizedBox(height: AppDimensions.p16),
        LuxuryTextField(
          label: 'Amount (₹)',
          hint: '0.00',
          controller: form.amountController,
          prefixIcon: AppIcons.cashback,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        ),
        const SizedBox(height: AppDimensions.p16),
        LuxuryTextField(
          label: 'Merchant',
          hint: 'e.g. Swiggy, Indian Oil',
          controller: form.merchantController,
          prefixIcon: AppIcons.store,
        ),
        const SizedBox(height: AppDimensions.p16),
        if (cards.isNotEmpty) ...[
          Text('Card', style: AppTypography.labelSmall.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppDimensions.p8),
          ValueListenableBuilder<int?>(
            valueListenable: form.cardId,
            builder: (context, selected, _) => Wrap(
              spacing: AppDimensions.p8,
              runSpacing: AppDimensions.p8,
              children: [
                for (final card in cards)
                  ChoiceChip(
                    label: Text('${card.label} •• ${card.last4}'),
                    selected: selected == card.userCardId,
                    selectedColor: c.accent,
                    backgroundColor: c.surfaceAlt,
                    labelStyle: AppTypography.labelSmall.copyWith(
                      color: selected == card.userCardId ? c.onAccent : c.textSecondary,
                    ),
                    onSelected: (on) => form.cardId.value = on ? card.userCardId : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p16),
        ],
        Text('Category', style: AppTypography.labelSmall.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppDimensions.p8),
        ValueListenableBuilder<SpendCategory>(
          valueListenable: form.category,
          builder: (context, selected, _) => Wrap(
            spacing: AppDimensions.p8,
            runSpacing: AppDimensions.p8,
            children: [
              for (final cat in SpendCategory.values)
                ChoiceChip(
                  avatar: Icon(cat.icon, size: AppDimensions.iconSm, color: selected == cat ? c.onAccent : cat.color),
                  label: Text(cat.label),
                  selected: selected == cat,
                  selectedColor: c.accent,
                  backgroundColor: c.surfaceAlt,
                  labelStyle: AppTypography.labelSmall.copyWith(
                    color: selected == cat ? c.onAccent : c.textSecondary,
                  ),
                  onSelected: (_) {
                    HapticsHelper.selection();
                    form.category.value = cat;
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.p16),
        ValueListenableBuilder<DateTime>(
          valueListenable: form.date,
          builder: (context, date, _) => LuxuryButton(
            label: _dateFormat.format(date),
            icon: AppIcons.calendar,
            variant: LuxuryButtonVariant.secondary,
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
              );
              if (picked != null) form.date.value = DateTime(picked.year, picked.month, picked.day, now.hour, now.minute);
            },
          ),
        ),
        const SizedBox(height: AppDimensions.p24),
        ValueListenableBuilder<bool>(
          valueListenable: form.isSaving,
          builder: (context, saving, _) => LuxuryButton(
            label: 'Save spend',
            icon: AppIcons.check,
            isLoading: saving,
            onPressed: () => _save(context),
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final form = context.read<_AddTransactionForm>();
    final amount = double.tryParse(form.amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      AppToast.error(context, title: 'Amount required', message: 'Enter an amount greater than zero.');
      return;
    }
    form.isSaving.value = true;
    final error = await context.read<ExpenseProvider>().addManualTransaction(
          amount: amount,
          merchant: form.merchantController.text,
          category: form.category.value,
          type: form.type.value,
          occurredAt: form.date.value,
          userCardId: form.cardId.value,
        );
    form.isSaving.value = false;
    if (!context.mounted) return;
    if (error != null) {
      AppToast.error(context, title: 'Not saved', message: error);
      return;
    }
    AppToast.success(context, title: 'Saved', message: 'Spend added to your insights.');
    Navigator.of(context).pop();
  }
}
