import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/card_formatter.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../../catalog/presentation/widgets/card_picker_sheet.dart';
import '../../../shell/presentation/providers/navigation_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/visual_credit_card.dart';

class AddCardScreen extends StatefulWidget {
  final CatalogCard? initialCard;
  const AddCardScreen({super.key, this.initialCard});

  static Future<void> open(BuildContext context, {CatalogCard? card}) {
    return Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => AddCardScreen(initialCard: card)),
    );
  }

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

/// Owns form controllers; everything else is ValueNotifier-driven.
class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _last4 = TextEditingController();
  final _nickname = TextEditingController();
  final _billingDay = TextEditingController();
  final _cvvFocus = FocusNode();

  late final ValueNotifier<CatalogCard?> _card = ValueNotifier(widget.initialCard);
  final ValueNotifier<bool> _saveSecrets = ValueNotifier(true);
  final ValueNotifier<bool> _saving = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _cvvFocus.addListener(() => _flip.value = _cvvFocus.hasFocus);
  }

  final ValueNotifier<bool> _flip = ValueNotifier(false);

  @override
  void dispose() {
    for (final c in [_number, _expiry, _cvv, _last4, _nickname, _billingDay]) {
      c.dispose();
    }
    _cvvFocus.dispose();
    _card.dispose();
    _saveSecrets.dispose();
    _saving.dispose();
    _flip.dispose();
    super.dispose();
  }

  String get _digits => _number.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _pickCard() async {
    final picked = await showCardPicker(context);
    if (picked?.catalog != null) _card.value = picked!.catalog;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final card = _card.value;
    if (card == null) {
      AppToast.warning(context, message: 'Choose which card this is first');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final withSecrets = _saveSecrets.value;
    final last4 = withSecrets ? _digits.substring(_digits.length - 4) : _last4.text;

    _saving.value = true;
    final created = await context.read<WalletProvider>().addCard(
          card: card,
          nickname: _nickname.text.trim().isEmpty ? card.shortName : _nickname.text.trim(),
          last4Digits: last4,
          billingCycleDay: int.tryParse(_billingDay.text),
          fullCardNumber: withSecrets ? _digits : null,
          cvv: withSecrets ? _cvv.text : null,
          expiry: withSecrets ? _expiry.text : null,
        );
    _saving.value = false;
    if (!mounted) return;

    if (created != null) {
      context.read<NavigationProvider>().setIndex(NavigationProvider.wallet);
      Navigator.of(context).pop();
      AppToast.success(context, message: '${created.nickname} added to your wallet');
    } else {
      AppToast.error(context, message: context.read<WalletProvider>().errorMessage ?? AppStrings.generalError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.screenWidth >= 900;
    final preview = _LivePreview(
      card: _card,
      number: _number,
      expiry: _expiry,
      cvv: _cvv,
      nickname: _nickname,
      last4: _last4,
      flip: _flip,
    );
    final form = _buildForm(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add card'),
        leading: IconButton(icon: const Icon(AppIcons.close, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: preview))),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 40, 40),
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: form),
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverPersistentHeader(pinned: true, delegate: _PreviewHeader(child: preview, width: context.screenWidth)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverToBoxAdapter(child: ContentWidth(child: form)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final c = context.colors;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Overline('1 · Card'),
          const SizedBox(height: 8),
          ValueListenableBuilder<CatalogCard?>(
            valueListenable: _card,
            builder: (context, card, _) => AppSurface(
              onTap: _pickCard,
              tone: card == null ? SurfaceTone.accent : SurfaceTone.base,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  card == null
                      ? IconHalo(icon: AppIcons.search, size: 40)
                      : CardThumb(cardName: card.name, bankName: card.bankName, network: card.network, imageUrl: card.imageUrl, width: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card?.shortName ?? 'Which card is this?', style: context.text.titleSmall),
                        Text(card == null ? 'Search from 700+ Indian credit cards' : card.bankName, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  Text(card == null ? 'Choose' : 'Change', style: context.text.labelMedium!.copyWith(color: c.accent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.p24),
          const Overline('2 · Details'),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _saveSecrets,
            builder: (context, withSecrets, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsGroup(
                  children: [
                    SettingsSwitchTile(
                      icon: AppIcons.shieldFill,
                      iconColor: c.success,
                      title: 'Save in secure vault',
                      subtitle: 'Copy number & CVV at checkout with biometrics',
                      value: withSecrets,
                      onChanged: (v) => _saveSecrets.value = v,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p14),
                AnimatedSwitcher(
                  duration: AppDimensions.mediumAnim,
                  child: withSecrets ? _secretFields(context) : _last4Field(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: _nickname,
                  label: 'Nickname (optional)',
                  hint: 'Travel card',
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: _billingDay,
                  label: 'Statement day',
                  hint: '1–28',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final d = int.tryParse(v);
                    return d == null || d < 1 || d > 28 ? '1 – 28' : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p24),
          ValueListenableBuilder<bool>(
            valueListenable: _saving,
            builder: (_, saving, _) => AppButton(
              label: 'Add to wallet',
              icon: AppIcons.lock,
              isLoading: saving,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: AppDimensions.p14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.lock, size: 13, color: c.textTertiary),
              const SizedBox(width: 6),
              Expanded(child: Text(AppStrings.zeroKnowledgeNote, style: context.text.bodySmall)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.mediumAnim);
  }

  Widget _secretFields(BuildContext context) {
    return Column(
      key: const ValueKey('secrets'),
      children: [
        AppTextField(
          controller: _number,
          label: 'Card number',
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
                validator: (v) => CardFormatter.validateExpiry(v ?? '') ? null : 'Invalid expiry',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _cvv,
                focusNode: _cvvFocus,
                label: 'CVV',
                hint: '•••',
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                autofillHints: const [AutofillHints.creditCardSecurityCode],
                validator: (v) => CardFormatter.validateCvv(v ?? '', network: CardFormatter.detectNetwork(_digits))
                    ? null
                    : 'Invalid CVV',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _last4Field() {
    return AppTextField(
      key: const ValueKey('last4'),
      controller: _last4,
      label: 'Last 4 digits',
      hint: '1234',
      helper: 'Used only to tell your cards apart',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
      validator: (v) => (v ?? '').length == 4 ? null : 'Enter 4 digits',
    );
  }
}

class _LivePreview extends StatelessWidget {
  final ValueNotifier<CatalogCard?> card;
  final TextEditingController number;
  final TextEditingController expiry;
  final TextEditingController cvv;
  final TextEditingController nickname;
  final TextEditingController last4;
  final ValueNotifier<bool> flip;

  const _LivePreview({
    required this.card,
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.nickname,
    required this.last4,
    required this.flip,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: ListenableBuilder(
        listenable: Listenable.merge([card, number, expiry, cvv, nickname, last4, flip]),
        builder: (context, _) {
          final digits = number.text.replaceAll(RegExp(r'\D'), '');
          final detected = CardFormatter.detectNetwork(digits);
          final c = card.value;
          final shownLast4 = digits.length >= 4
              ? digits.substring(digits.length - 4)
              : (last4.text.isNotEmpty ? last4.text : '0000');
          return VisualCreditCard(
            showBack: flip.value,
            data: CardFaceData(
              bankName: c?.bankName ?? 'Your bank',
              cardName: c?.shortName ?? 'Credit card',
              network: detected != 'Credit Card' ? detected : (c?.network ?? 'Visa'),
              last4: shownLast4,
              nickname: nickname.text.isEmpty ? null : nickname.text,
              fullNumber: digits.isEmpty ? null : digits,
              expiry: expiry.text.isEmpty ? null : expiry.text,
              cvv: cvv.text.isEmpty ? null : '•' * cvv.text.length,
            ),
          );
        },
      ),
    );
  }
}

class _PreviewHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double width;

  _PreviewHeader({required this.child, required this.width});

  double get _cardHeight => (width.clamp(0, 400) - 32) / AppDimensions.cardAspectRatio;

  @override
  double get maxExtent => _cardHeight + 24;

  @override
  double get minExtent => _cardHeight * 0.55 + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return ColoredBox(
      color: context.colors.canvas,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Transform.scale(scale: 1 - t * 0.45, alignment: Alignment.center, child: child),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PreviewHeader oldDelegate) => oldDelegate.width != width || oldDelegate.child != child;
}
