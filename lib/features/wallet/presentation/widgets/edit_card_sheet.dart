import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/card_formatter.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/user_card.dart';
import '../providers/wallet_provider.dart';

Future<void> showEditCardSheet(BuildContext context, UserCard card) {
  return showAppSheet<void>(context, builder: (_) => _EditCardSheet(card: card));
}

class _EditCardSheet extends StatefulWidget {
  final UserCard card;
  const _EditCardSheet({required this.card});

  @override
  State<_EditCardSheet> createState() => _EditCardSheetState();
}

/// Owns the form controllers.
class _EditCardSheetState extends State<_EditCardSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nickname = TextEditingController(text: widget.card.nickname);
  late final _billingDay = TextEditingController(text: widget.card.billingCycleDay?.toString() ?? '');
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _saving = ValueNotifier<bool>(false);
  final _editingSecrets = ValueNotifier<bool>(false);

  String get _digits => _number.text.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    for (final c in [_nickname, _billingDay, _number, _expiry, _cvv]) {
      c.dispose();
    }
    _saving.dispose();
    _editingSecrets.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final wallet = context.read<WalletProvider>();
    final day = int.tryParse(_billingDay.text);
    _saving.value = true;

    var card = widget.card;
    if (_editingSecrets.value) {
      final status = await wallet.updateSecrets(
        card,
        cardNumber: _digits,
        cvv: _cvv.text.trim(),
        expiry: _expiry.text.trim(),
      );
      if (!mounted) return;
      if (!status.isSuccess) {
        _saving.value = false;
        AppToast.warning(context, message: status.message);
        return;
      }
      card = wallet.cards.firstWhere((c) => c.id == card.id, orElse: () => card);
    }

    final ok = await wallet.updateCard(card, nickname: _nickname.text.trim(), billingCycleDay: day);
    _saving.value = false;
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      AppToast.success(context, message: 'Card updated');
    } else {
      AppToast.error(context, message: wallet.errorMessage ?? 'Couldn\'t update card');
    }
  }

  Future<void> _removeSecrets() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove saved card number?'),
        content: const Text('The number, expiry and CVV are erased from this device. The card stays in your wallet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final status = await context.read<WalletProvider>().removeSecrets(widget.card);
    if (!mounted) return;
    if (status.isSuccess) {
      Navigator.of(context).pop();
      AppToast.success(context, message: 'Card number removed from this device');
    } else {
      AppToast.warning(context, message: status.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(title: 'Edit card', subtitle: '${widget.card.cardName} •• ${widget.card.last4Digits}'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nickname,
                      label: 'Nickname',
                      hint: 'e.g. Travel card',
                      prefixIcon: AppIcons.tag,
                      maxLength: 24,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppDimensions.p14),
                    AppTextField(
                      controller: _billingDay,
                      label: 'Statement day',
                      hint: '1 – 28',
                      helper: 'Used for statement and due-date reminders',
                      prefixIcon: AppIcons.calendar,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final day = int.tryParse(v);
                        return day == null || day < 1 || day > 28 ? 'Pick a day between 1 and 28' : null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.p16),
                    ValueListenableBuilder<bool>(
                      valueListenable: _editingSecrets,
                      builder: (_, editing, _) => AnimatedSize(
                        duration: AppDimensions.mediumAnim,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: editing ? _secretFields() : _vaultRow(),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.p20),
                    ValueListenableBuilder<bool>(
                      valueListenable: _saving,
                      builder: (_, saving, _) => AppButton(label: 'Save changes', isLoading: saving, onPressed: _save),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vaultRow() {
    final c = context.colors;
    final saved = widget.card.hasVaultDetails;
    return AppSurface(
      tone: SurfaceTone.alt,
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          IconHalo(icon: saved ? AppIcons.shieldFill : AppIcons.lock, size: 34, iconSize: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(saved ? 'Card number saved on device' : 'No card number saved', style: context.text.titleSmall),
                Text(
                  saved ? 'Encrypted in your phone\'s secure hardware' : 'Save it to copy with a fingerprint later',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          if (saved)
            IconButton(
              tooltip: 'Remove from device',
              onPressed: _removeSecrets,
              icon: Icon(AppIcons.delete, size: 18, color: c.danger),
            ),
          TextButton(
            onPressed: () => _editingSecrets.value = true,
            child: Text(saved ? 'Change' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _secretFields() {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(AppIcons.shieldFill, size: 14, color: c.success),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Stays on this device. Only the last 4 digits sync.',
                style: context.text.labelSmall!.copyWith(color: c.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                _number.clear();
                _expiry.clear();
                _cvv.clear();
                _editingSecrets.value = false;
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: _number,
          label: 'New card number',
          hint: '0000 0000 0000 0000',
          prefixIcon: AppIcons.card,
          keyboardType: TextInputType.number,
          inputFormatters: [CardNumberInputFormatter()],
          autofillHints: const [AutofillHints.creditCardNumber],
          validator: (_) {
            if (_digits.length < 13) return 'Enter the full card number';
            if (!CardFormatter.validateCardNumber(_digits)) return 'This card number looks wrong';
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.p14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _expiry,
                label: 'Expiry',
                hint: 'MM/YY',
                keyboardType: TextInputType.number,
                inputFormatters: [CardExpiryInputFormatter()],
                autofillHints: const [AutofillHints.creditCardExpirationDate],
                validator: (v) => (v ?? '').isEmpty || CardFormatter.validateExpiry(v!) ? null : 'Invalid expiry',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _cvv,
                label: 'CVV',
                hint: '•••',
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                autofillHints: const [AutofillHints.creditCardSecurityCode],
                validator: (v) =>
                    (v ?? '').isEmpty || CardFormatter.validateCvv(v!, network: CardFormatter.detectNetwork(_digits))
                        ? null
                        : 'Invalid CVV',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
