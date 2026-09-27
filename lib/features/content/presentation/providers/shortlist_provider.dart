import 'package:flutter/foundation.dart';

import '../../../../core/network/api_result.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../data/content_repository.dart';

/// Catalog cards the user might apply for. Not the wallet.
class ShortlistProvider extends ChangeNotifier {
  final ContentRepository _repository;

  ShortlistProvider(this._repository);

  List<CatalogCard> cards = const [];
  bool loading = false;
  String? error;

  bool isSaved(int cardId) => cards.any((c) => c.id == cardId);

  Future<void> refresh() async {
    loading = cards.isEmpty;
    error = null;
    notifyListeners();
    final result = await _repository.savedCards();
    loading = false;
    if (result case ApiSuccess(:final data)) {
      cards = data;
    } else {
      error = result.errorOrNull;
    }
    notifyListeners();
  }

  void clear() {
    cards = const [];
    error = null;
    notifyListeners();
  }

  /// Returns false when the request failed.
  Future<bool> toggle(int cardId) async {
    final saved = isSaved(cardId);
    final result = saved ? await _repository.unsaveCard(cardId) : await _repository.saveCard(cardId);
    if (!result.isSuccess) {
      error = result.errorOrNull;
      notifyListeners();
      return false;
    }
    if (saved) {
      cards = cards.where((c) => c.id != cardId).toList();
      notifyListeners();
    } else {
      await refresh();
    }
    return true;
  }
}
