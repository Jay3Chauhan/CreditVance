import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/card_tab.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/bank_model.dart';
import '../models/catalog_card_model.dart';
import '../models/category_model.dart';

/// Catalog repository: server pagination, TTL cache for the default first
/// page, and an offline fallback over the bundled sample catalog.
class CatalogRepositoryImpl implements CatalogRepository {
  final ApiClient _apiClient;
  final LocalCacheService _cacheService;

  CatalogRepositoryImpl({
    required ApiClient apiClient,
    required LocalCacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<ApiResult<PagedResult<CatalogCard>>> getCards({
    CatalogQuery query = const CatalogQuery(),
    int page = 1,
    int limit = ApiEndpoints.pageSize,
    bool forceRefresh = false,
  }) async {
    final cacheable = page == 1 && query.isDefault;

    if (cacheable && !forceRefresh) {
      final cached = _readCachedFirstPage();
      if (cached != null) return ApiSuccess(cached);
    }

    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort_by': query.sortBy,
      if (query.search != null && query.search!.isNotEmpty) 'search': query.search,
      'bank_slug': ?query.bankSlug,
      'network': ?query.network,
      'fee_type': ?query.feeType,
      if (query.popularOnly) 'is_popular': true,
    };

    final result = await _apiClient.get<List<CatalogCard>>(
      path: ApiEndpoints.cards,
      queryParameters: params,
      fromJson: (data) {
        final list = data is List ? data : (data?['items'] as List? ?? const []);
        return list.map((e) => CatalogCardModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );

    if (result case ApiSuccess(:final data, :final meta)) {
      final paged = PagedResult.fromMeta(data, meta, page: page, limit: limit);
      if (cacheable) _writeCachedFirstPage(paged);
      return ApiSuccess(paged);
    }

    final failure = result as ApiFailure<List<CatalogCard>>;
    if (page == 1) {
      final cached = query.isDefault ? _readCachedFirstPage(ignoreTtl: true) : null;
      if (cached != null) return ApiSuccess(cached);
      return ApiSuccess(_offlineFilter(query));
    }
    return ApiFailure(failure.message, statusCode: failure.statusCode, isNetworkError: failure.isNetworkError);
  }

  PagedResult<CatalogCard>? _readCachedFirstPage({bool ignoreTtl = false}) {
    final raw = _cacheService.getCatalogCache(ignoreTtl: ignoreTtl);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = (map['items'] as List)
          .map((e) => CatalogCardModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (items.isEmpty) return null;
      return PagedResult(
        items: items,
        page: 1,
        total: (map['total'] as num?)?.toInt() ?? items.length,
        hasNext: map['has_next'] as bool? ?? true,
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  void _writeCachedFirstPage(PagedResult<CatalogCard> page) {
    _cacheService.setCatalogCache(jsonEncode({
      'items': page.items.map((c) => CatalogCardModel.fromEntity(c).toJson()).toList(),
      'total': page.total,
      'has_next': page.hasNext,
    }));
  }

  PagedResult<CatalogCard> _offlineFilter(CatalogQuery query) {
    Iterable<CatalogCard> list = MockSeedData.sampleCards;
    final s = query.search?.toLowerCase();
    if (s != null && s.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(s) || c.bankName.toLowerCase().contains(s));
    }
    if (query.network != null) {
      list = list.where((c) => CatalogCardModel.networkCode(c.network) == query.network);
    }
    switch (query.feeType) {
      case 'free':
        list = list.where((c) => c.annualFee == 0);
      case 'lt1k':
        list = list.where((c) => c.annualFee > 0 && c.annualFee <= 1000);
      case '1k5k':
        list = list.where((c) => c.annualFee > 1000 && c.annualFee <= 5000);
      case 'gt5k':
        list = list.where((c) => c.annualFee > 5000);
    }
    final items = list.toList();
    return PagedResult(items: items, page: 1, total: items.length, hasNext: false, fromCache: true);
  }

  @override
  Future<ApiResult<CatalogCard>> getCardBySlug(String slug) async {
    final result = await _apiClient.get<CatalogCard>(
      path: ApiEndpoints.cardDetail(slug),
      fromJson: (data) => CatalogCardModel.fromJson(data as Map<String, dynamic>),
    );
    if (result.isSuccess) return result;
    final mock = MockSeedData.sampleCards.where((c) => c.slug == slug).firstOrNull;
    if (mock != null) return ApiSuccess(mock);
    return result;
  }

  @override
  Future<ApiResult<CardTab>> getCardTab(String slug, String tabName) {
    return _apiClient.get<CardTab>(
      path: ApiEndpoints.cardTab(slug, tabName),
      fromJson: (data) => CardTab.fromJson(tabName, data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<List<Bank>>> getBanks({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cacheService.getBanksCache();
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached) as List;
          return ApiSuccess(decoded.map((e) => BankModel.fromJson(e as Map<String, dynamic>)).toList());
        } catch (_) {}
      }
    }

    final result = await _apiClient.get<List<Bank>>(
      path: ApiEndpoints.banks,
      fromJson: (data) => (data as List).map((e) => BankModel.fromJson(e as Map<String, dynamic>)).toList(),
    );

    if (result case ApiSuccess(:final data)) {
      _cacheService.setBanksCache(jsonEncode(data.map((b) => (b as BankModel).toJson()).toList()));
      return result;
    }
    return const ApiSuccess(MockSeedData.banks);
  }

  @override
  Future<ApiResult<List<SpendCategory>>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cacheService.getCategoriesCache();
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached) as List;
          return ApiSuccess(decoded.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList());
        } catch (_) {}
      }
    }

    final result = await _apiClient.get<List<SpendCategory>>(
      path: ApiEndpoints.categories,
      fromJson: (data) => (data as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList(),
    );

    if (result case ApiSuccess(:final data)) {
      _cacheService.setCategoriesCache(jsonEncode(data.map((c) => (c as CategoryModel).toJson()).toList()));
      return result;
    }
    return const ApiSuccess(MockSeedData.categories);
  }

  @override
  Future<void> clearCache() => _cacheService.clearCatalogCaches();
}
