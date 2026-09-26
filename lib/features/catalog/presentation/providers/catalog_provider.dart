import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Catalog browsing: server-side pagination, debounced search, filters and
/// a compare tray.
class CatalogProvider extends ChangeNotifier {
  final CatalogRepository _repository;

  CatalogProvider(this._repository);

  static const int maxCompare = 3;

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<CatalogCard> _cards = [];
  List<CatalogCard> get cards => List.unmodifiable(_cards);

  List<Bank> _banks = [];
  List<Bank> get banks => _banks;

  List<SpendCategory> _categories = [];
  List<SpendCategory> get categories => _categories;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CatalogQuery _query = const CatalogQuery();
  CatalogQuery get query => _query;
  bool get hasActiveFilters => !_query.isDefault;

  int _page = 1;
  int _total = 0;
  int get total => _total;
  bool _hasNext = false;
  bool get hasNext => _hasNext;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  String? _loadMoreError;
  String? get loadMoreError => _loadMoreError;
  bool _fromCache = false;
  bool get isShowingCached => _fromCache;

  final List<CatalogCard> _compare = [];
  List<CatalogCard> get compareList => List.unmodifiable(_compare);
  bool isInCompare(int id) => _compare.any((c) => c.id == id);

  Timer? _debounce;
  int _requestSeq = 0;

  Future<void> init() async {
    if (_state != ViewState.initial) return;
    _setState(ViewState.loading);
    await Future.wait([_loadTaxonomies(), _fetchFirstPage()]);
  }

  Future<void> _loadTaxonomies({bool force = false}) async {
    final results = await Future.wait([
      _repository.getBanks(forceRefresh: force),
      _repository.getCategories(forceRefresh: force),
    ]);
    _banks = (results[0].dataOrNull as List<Bank>?) ?? _banks;
    _categories = (results[1].dataOrNull as List<SpendCategory>?) ?? _categories;
    notifyListeners();
  }

  Future<void> _fetchFirstPage({bool force = false}) async {
    final seq = ++_requestSeq;
    final result = await _repository.getCards(query: _query, page: 1, forceRefresh: force);
    if (seq != _requestSeq) return; // A newer query superseded this one.

    result.when(
      success: (paged) {
        _cards = paged.items;
        _page = 1;
        _total = paged.total;
        _hasNext = paged.hasNext;
        _fromCache = paged.fromCache;
        _errorMessage = null;
        _loadMoreError = null;
        _setState(_cards.isEmpty ? ViewState.empty : ViewState.loaded);
      },
      failure: (message, _) {
        _errorMessage = message;
        _setState(_cards.isEmpty ? ViewState.error : ViewState.loaded);
      },
    );
  }

  /// Loads the next page. Safe to call repeatedly from scroll listeners.
  Future<void> loadMore() async {
    if (!_hasNext || _isLoadingMore || _state.isLoading) return;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    final seq = _requestSeq;
    final result = await _repository.getCards(query: _query, page: _page + 1);
    if (seq != _requestSeq) {
      _isLoadingMore = false;
      return;
    }

    result.when(
      success: (paged) {
        final known = _cards.map((c) => c.id).toSet();
        _cards = [..._cards, ...paged.items.where((c) => !known.contains(c.id))];
        _page = paged.page;
        _total = paged.total;
        _hasNext = paged.hasNext;
      },
      failure: (message, _) => _loadMoreError = message,
    );
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _setState(_cards.isEmpty ? ViewState.loading : ViewState.refreshing);
    await Future.wait([_loadTaxonomies(force: true), _fetchFirstPage(force: true)]);
  }

  void _applyQuery(CatalogQuery next, {bool debounce = false}) {
    _query = next;
    _debounce?.cancel();
    if (debounce) {
      notifyListeners();
      _debounce = Timer(AppDimensions.debounce, () {
        _setState(ViewState.loading);
        _fetchFirstPage();
      });
    } else {
      _setState(ViewState.loading);
      _fetchFirstPage();
    }
  }

  void setSearchQuery(String value) {
    final trimmed = value.trim();
    if ((_query.search ?? '') == trimmed) return;
    _applyQuery(_query.copyWith(search: trimmed), debounce: true);
  }

  void setBankFilter(String? slug) {
    if (_query.bankSlug == slug) return;
    _applyQuery(_query.copyWith(bankSlug: slug));
  }

  void setNetworkFilter(String? code) {
    if (_query.network == code) return;
    _applyQuery(_query.copyWith(network: code));
  }

  void setFeeFilter(String? feeType) {
    if (_query.feeType == feeType) return;
    _applyQuery(_query.copyWith(feeType: feeType));
  }

  void setPopularOnly(bool value) {
    if (_query.popularOnly == value) return;
    _applyQuery(_query.copyWith(popularOnly: value));
  }

  void setSortBy(String sort) {
    if (_query.sortBy == sort) return;
    _applyQuery(_query.copyWith(sortBy: sort));
  }

  /// Applies several filters at once (from the filter sheet).
  void applyFilters(CatalogQuery next) {
    _applyQuery(next.copyWith(search: _query.search ?? ''));
  }

  void clearFilters({bool keepSearch = true}) {
    _applyQuery(CatalogQuery(search: keepSearch ? _query.search : null));
  }

  /// Returns false when the compare tray is full.
  bool toggleCompare(CatalogCard card) {
    final idx = _compare.indexWhere((c) => c.id == card.id);
    if (idx != -1) {
      _compare.removeAt(idx);
    } else {
      if (_compare.length >= maxCompare) return false;
      _compare.add(card);
    }
    notifyListeners();
    return true;
  }

  void clearCompare() {
    _compare.clear();
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _repository.clearCache();
    await refresh();
  }

  void _setState(ViewState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
