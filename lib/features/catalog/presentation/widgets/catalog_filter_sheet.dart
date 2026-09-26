import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../providers/catalog_provider.dart';

class CatalogFilters {
  const CatalogFilters._();

  static const networks = {
    'VISA': 'Visa',
    'MASTERCARD': 'Mastercard',
    'RUPAY': 'RuPay',
    'AMEX': 'Amex',
  };

  static const fees = {
    'free': 'Lifetime free',
    'lt1k': 'Up to ₹1K',
    '1k5k': '₹1K – 5K',
    'gt5k': '₹5K+',
  };

  static const sorts = {
    'popular': 'Most popular',
    'return': 'Highest return',
    'fee_asc': 'Fee: low to high',
    'fee_desc': 'Fee: high to low',
    'name': 'Name A–Z',
  };
}

Future<void> showCatalogFilterSheet(BuildContext context) {
  final provider = context.read<CatalogProvider>();
  return showAppSheet<void>(
    context,
    builder: (_) => ChangeNotifierProvider.value(value: provider, child: const _FilterSheet()),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

/// Holds a draft query until "Show results" is tapped.
class _FilterSheetState extends State<_FilterSheet> {
  late final ValueNotifier<CatalogQuery> _draft = ValueNotifier(context.read<CatalogProvider>().query);

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: ValueListenableBuilder<CatalogQuery>(
        valueListenable: _draft,
        builder: (context, q, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Filters', style: context.text.headlineSmall)),
                    if (q.activeFilterCount > 0)
                      AppButton.ghost(
                        label: 'Reset',
                        onPressed: () => _draft.value = CatalogQuery(search: q.search),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p16),
                const Overline('Sort by'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in CatalogFilters.sorts.entries)
                      AppChip(
                        label: e.value,
                        selected: q.sortBy == e.key,
                        onTap: () => _draft.value = q.copyWith(sortBy: e.key),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p20),
                const Overline('Annual fee'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in CatalogFilters.fees.entries)
                      AppChip(
                        label: e.value,
                        selected: q.feeType == e.key,
                        onTap: () => _draft.value = q.copyWith(feeType: q.feeType == e.key ? null : e.key),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p20),
                const Overline('Network'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in CatalogFilters.networks.entries)
                      AppChip(
                        label: e.value,
                        selected: q.network == e.key,
                        onTap: () => _draft.value = q.copyWith(network: q.network == e.key ? null : e.key),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p20),
                SettingsGroup(
                  children: [
                    SettingsSwitchTile(
                      icon: AppIcons.star,
                      iconColor: c.accent,
                      title: 'Popular cards only',
                      value: q.popularOnly,
                      onChanged: (v) => _draft.value = q.copyWith(popularOnly: v),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p24),
                AppButton(
                  label: 'Show results',
                  onPressed: () {
                    context.read<CatalogProvider>().applyFilters(q);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
