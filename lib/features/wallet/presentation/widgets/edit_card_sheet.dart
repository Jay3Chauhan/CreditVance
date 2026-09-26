import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_sheet.dart';
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
  late final _nickname = TextEditingController(text: widget.card.nickname);
  late final _billingDay = TextEditingController(text: widget.card.billingCycleDay?.toString() ?? '');
  final _saving = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _nickname.dispose();
    _billingDay.dispose();
    _saving.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final day = int.tryParse(_billingDay.text);
    if (_billingDay.text.isNotEmpty && (day == null || day < 1 || day > 28)) {
      AppToast.warning(context, message: 'Billing day must be between 1 and 28');
      return;
    }
    _saving.value = true;
    final ok = await context.read<WalletProvider>().updateCard(
          widget.card,
          nickname: _nickname.text.trim(),
          billingCycleDay: day,
        );
    _saving.value = false;
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      AppToast.success(context, message: 'Card updated');
    } else {
      AppToast.error(context, message: context.read<WalletProvider>().errorMessage ?? 'Couldn\'t update card');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: 'Edit card', subtitle: '${widget.card.cardName} •• ${widget.card.last4Digits}'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
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
    );
  }
}
