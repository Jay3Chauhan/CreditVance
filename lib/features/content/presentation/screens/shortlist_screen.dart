import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../catalog/presentation/widgets/catalog_card_tile.dart';
import '../providers/shortlist_provider.dart';

class ShortlistScreen extends StatelessWidget {
  const ShortlistScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShortlistScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final shortlist = context.watch<ShortlistProvider>();
    final gutter = context.gutter();
    return Scaffold(
      appBar: AppBar(title: const Text('Shortlist')),
      body: RefreshIndicator(
        onRefresh: shortlist.refresh,
        child: shortlist.loading && shortlist.cards.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : shortlist.cards.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      EmptyStateView(
                        icon: AppIcons.bookmark,
                        title: 'Nothing saved yet',
                        message: 'Bookmark cards you might apply for. Your wallet stays separate — those are cards you already hold.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 32),
                    itemCount: shortlist.cards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => CatalogCardTile(card: shortlist.cards[i]),
                  ),
      ),
    );
  }
}
