import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/card_tab.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Scoped to one detail page: loads the full card and its API tabs.
class CardDetailProvider extends ChangeNotifier {
  final CatalogRepository _repository;
  final String slug;

  CardDetailProvider(this._repository, {required this.slug, CatalogCard? initial}) : _card = initial {
    _load();
  }

  CatalogCard? _card;
  CatalogCard? get card => _card;

  ViewState _state = ViewState.loading;
  ViewState get state => _state;

  String? _error;
  String? get error => _error;

  final Map<String, CardTab> _tabs = {};
  Map<String, CardTab> get tabs => Map.unmodifiable(_tabs);

  bool _disposed = false;

  Future<void> _load() async {
    final result = await _repository.getCardBySlug(slug);
    if (_disposed) return;
    switch (result) {
      case ApiSuccess(:final data):
        _card = data;
        _state = ViewState.loaded;
        notifyListeners();
        _loadTabs(data.availableTabs);
      case ApiFailure(:final message):
        _error = message;
        _state = _card == null ? ViewState.error : ViewState.loaded;
        notifyListeners();
    }
  }

  Future<void> _loadTabs(List<String> names) async {
    for (final name in names.take(6)) {
      final result = await _repository.getCardTab(slug, name);
      if (_disposed) return;
      if (result case ApiSuccess(:final data) when !data.isEmpty) {
        _tabs[name] = data;
        notifyListeners();
      }
    }
  }

  Future<void> retry() async {
    _state = ViewState.loading;
    notifyListeners();
    await _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
