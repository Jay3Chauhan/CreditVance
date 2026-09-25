import 'package:flutter/foundation.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Provider for Cards Catalog, filters, and taxonomies.
/// Adheres strictly to Zero-setState architecture.
class CatalogProvider extends ChangeNotifier {
  final CatalogRepository _repository;

  CatalogProvider(this._repository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<CatalogCard> _cards = [];
  List<CatalogCard> get cards => _cards;

  List<Bank> _banks = [];
  List<Bank> get banks => _banks;

  List<SpendCategory> _categories = [];
  List<SpendCategory> get categories => _categories;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filters
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedBankSlug;
  String? get selectedBankSlug => _selectedBankSlug;

  String? _selectedNetwork;
  String? get selectedNetwork => _selectedNetwork;

  String? _selectedFeeType;
  String? get selectedFeeType => _selectedFeeType;

  String _sortBy = 'popular';
  String get sortBy => _sortBy;

  int _page = 1;
  int get page => _page;
  bool _hasNextPage = true;
  bool get hasNextPage => _hasNextPage;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedBankSlug != null ||
      _selectedNetwork != null ||
      _selectedFeeType != null ||
      _sortBy != 'popular';

  /// Initial load of catalog, banks, and categories
  Future<void> init() async {
    if (_state != ViewState.initial) return;
    _setState(ViewState.loading);

    // Parallel load of taxonomies and first page of cards
    await Future.wait([
      _loadTaxonomies(),
      _fetchCards(page: 1, reset: true),
    ]);
  }

  Future<void> _loadTaxonomies() async {
    final banksResult = await _repository.getBanks();
    if (banksResult.isSuccess) {
      _banks = banksResult.dataOrNull ?? [];
    }

    final catResult = await _repository.getCategories();
    if (catResult.isSuccess) {
      _categories = catResult.dataOrNull ?? [];
    }
  }

  /// Fetches cards matching current active filters
  Future<void> _fetchCards({int page = 1, bool reset = false, bool isRefresh = false}) async {
    if (reset) {
      _page = 1;
    }

    final result = await _repository.getCards(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      bankSlug: _selectedBankSlug,
      network: _selectedNetwork,
      feeType: _selectedFeeType,
      sortBy: _sortBy,
      page: page,
      forceRefresh: isRefresh,
    );

    result.when(
      success: (cardsList) {
        if (reset) {
          _cards = cardsList;
        } else {
          _cards.addAll(cardsList);
        }
        _page = page;
        _hasNextPage = cardsList.length >= 20;
        _errorMessage = null;

        if (_cards.isEmpty) {
          _setState(ViewState.empty);
        } else {
          _setState(ViewState.loaded);
        }
      },
      failure: (message, statusCode) {
        _errorMessage = message;
        if (_cards.isEmpty) {
          _setState(ViewState.error);
        } else {
          _setState(ViewState.loaded);
        }
      },
    );
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    _setState(ViewState.refreshing);
    await _fetchCards(page: 1, reset: true, isRefresh: true);
  }

  /// Update search query
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _setState(ViewState.loading);
    _fetchCards(page: 1, reset: true);
  }

  /// Filter by Bank
  void setBankFilter(String? bankSlug) {
    if (_selectedBankSlug == bankSlug) return;
    _selectedBankSlug = bankSlug;
    _setState(ViewState.loading);
    _fetchCards(page: 1, reset: true);
  }

  /// Filter by Network (Visa, Mastercard, Amex, RuPay)
  void setNetworkFilter(String? network) {
    if (_selectedNetwork == network) return;
    _selectedNetwork = network;
    _setState(ViewState.loading);
    _fetchCards(page: 1, reset: true);
  }

  /// Filter by Fee Tier (free, lt1k, 1k5k, gt5k)
  void setFeeFilter(String? feeType) {
    if (_selectedFeeType == feeType) return;
    _selectedFeeType = feeType;
    _setState(ViewState.loading);
    _fetchCards(page: 1, reset: true);
  }

  /// Change Sort order
  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    _setState(ViewState.loading);
    _fetchCards(page: 1, reset: true);
  }

  /// Clear all active filters
  void clearFilters() {
    _searchQuery = '';
    _selectedBankSlug = null;
    _selectedNetwork = null;
    _selectedFeeType = null;
    _sortBy = 'popular';
    _setState(ViewState.loading);
    _fetchCards(page: 1, reset: true);
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
}
