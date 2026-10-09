import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../wallet/domain/entities/user_card.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Either a catalog card or a wallet card picked from [showCardPicker].
class PickedCard {
  final CatalogCard? catalog;
  final UserCard? wallet;
  const PickedCard.catalog(CatalogCard this.catalog) : wallet = null;
  const PickedCard.wallet(UserCard this.wallet) : catalog = null;
}

/// Searchable card picker backed by the paginated `/cards` endpoint.
/// When [walletCards] is provided they're listed first.
Future<PickedCard?> showCardPicker(
  BuildContext context, {
  String title = 'Choose your card',
  List<UserCard> walletCards = const [],
}) {
  return showAppSheet<PickedCard>(
    context,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _CardPicker(title: title, walletCards: walletCards, scroll: scroll),
    ),
  );
}

class _CardPicker extends StatefulWidget {
  final String title;
  final List<UserCard> walletCards;
  final ScrollController scroll;

  const _CardPicker({required this.title, required this.walletCards, required this.scroll});

  @override
  State<_CardPicker> createState() => _CardPickerState();
}

/// Owns the search controller, debounce timer and result notifiers.
class _CardPickerState extends State<_CardPicker> {
  final _search = TextEditingController();
  final ValueNotifier<List<CatalogCard>?> _results = ValueNotifier(null);
  final ValueNotifier<String> _query = ValueNotifier('');
  Timer? _debounce;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _fetch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _results.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _query.value = v.trim();
    _debounce?.cancel();
    _debounce = Timer(AppDimensions.debounce, () => _fetch(v.trim()));
  }

  Future<void> _fetch(String q) async {
    final seq = ++_seq;
    _results.value = null;
    final repo = context.read<CatalogRepository>();
    final result = await repo.getCards(query: CatalogQuery(search: q), limit: 30);
    if (!mounted || seq != _seq) return;
    _results.value = switch (result) {
      ApiSuccess(:final data) => data.items,
      ApiFailure() => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        SheetHeader(title: widget.title),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: AppTextField(
            controller: _search,
            hint: 'Search 700+ cards or banks',
            prefixIcon: AppIcons.search,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: _query,
            builder: (context, q, _) {
              final wallet = q.isEmpty
                  ? widget.walletCards
                  : widget.walletCards
                      .where((w) => '${w.cardName} ${w.bankName} ${w.nickname}'.toLowerCase().contains(q.toLowerCase()))
                      .toList();
              return ValueListenableBuilder<List<CatalogCard>?>(
                valueListenable: _results,
                builder: (context, results, _) {
                  return ListView(
                    controller: widget.scroll,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    children: [
                      if (wallet.isNotEmpty) ...[
                        const Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 4), child: Overline('Your wallet')),
                        for (final w in wallet)
                          _PickerRow(
                            title: w.nickname.isEmpty ? w.cardName : w.nickname,
                            subtitle: '${w.bankName} •• ${w.last4Digits}',
                            thumb: CardThumb(cardName: w.cardName, bankName: w.bankName, network: w.network, width: 52),
                            trailing: Icon(AppIcons.navWalletActive, size: 16, color: c.accent),
                            onTap: () => Navigator.pop(context, PickedCard.wallet(w)),
                          ),
                        const Padding(padding: EdgeInsets.fromLTRB(8, 16, 8, 4), child: Overline('All cards')),
                      ],
                      if (results == null)
                        for (var i = 0; i < 6; i++)
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SkeletonRow())
                      else if (results.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No cards match "$q"', textAlign: TextAlign.center, style: context.text.bodyMedium),
                        )
                      else
                        for (final card in results)
                          _PickerRow(
                            title: card.shortName,
                            subtitle: '${card.bankName} · ${card.returnLabel} return',
                            thumb: CardThumb(
                              cardName: card.name,
                              bankName: card.bankName,
                              network: card.network,
                              imageUrl: card.imageUrl,
                              width: 52,
                            ),
                            onTap: () => Navigator.pop(context, PickedCard.catalog(card)),
                          ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget thumb;
  final Widget? trailing;
  final VoidCallback onTap;

  const _PickerRow({required this.title, required this.subtitle, required this.thumb, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedMd),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: thumb,
      title: Text(title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing,
    );
  }
}
