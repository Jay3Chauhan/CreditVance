import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/content_repository.dart';
import '../../domain/content_models.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen()));
  }

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  List<FaqItem>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<ContentRepository>().faq();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.dataOrNull;
      _error = result.errorOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? const <FaqItem>[];
    final topics = <String, List<FaqItem>>{};
    for (final item in items) {
      topics.putIfAbsent(item.topic, () => []).add(item);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(pinned: true, title: Text('Help', style: context.text.titleMedium)),
            if (_loading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
            else if (_error != null && items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateView(message: _error!, onRetry: _load),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(context.gutter(), 8, context.gutter(), 32),
                sliver: SliverList.list(
                  children: [
                    for (final entry in topics.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(_label(entry.key), style: context.text.titleSmall),
                      ),
                      AppSurface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final item in entry.value)
                              ExpansionTile(
                                title: Text(item.question, style: context.text.titleSmall),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(item.answer, style: context.text.bodyMedium),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _label(String topic) {
    if (topic.isEmpty) return 'General';
    return topic[0].toUpperCase() + topic.substring(1);
  }
}
