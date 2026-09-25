import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/catalog_card.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/bank_model.dart';
import '../models/catalog_card_model.dart';
import '../models/category_model.dart';

/// Implementation of CatalogRepository with Cache-First strategy and Mock fallback
class CatalogRepositoryImpl implements CatalogRepository {
  final ApiClient _apiClient;
  final LocalCacheService _cacheService;

  CatalogRepositoryImpl({
    required ApiClient apiClient,
    required LocalCacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<ApiResult<List<CatalogCard>>> getCards({
    String? search,
    String? bankSlug,
    String? network,
    String? feeType,
    bool? isPopular,
    String? sortBy,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (bankSlug != null && bankSlug.isNotEmpty) query['bank_slug'] = bankSlug;
    if (network != null && network.isNotEmpty) query['network'] = network;
    if (feeType != null && feeType.isNotEmpty) query['fee_type'] = feeType;
    if (isPopular != null) query['is_popular'] = isPopular;
    if (sortBy != null && sortBy.isNotEmpty) query['sort_by'] = sortBy;

    // Check local cache if not forced refresh and on first page
    if (!forceRefresh && page == 1 && search == null && bankSlug == null) {
      final cachedJson = _cacheService.getCatalogCache();
      if (cachedJson != null) {
        try {
          final List decoded = jsonDecode(cachedJson) as List;
          final cachedCards = decoded.map((e) => CatalogCardModel.fromJson(e)).toList();
          // Ensure cached data contains valid card names before serving
          if (cachedCards.isNotEmpty &&
              cachedCards.every((c) => c.name.trim().isNotEmpty && c.name != 'Credit Card')) {
            return ApiSuccess(cachedCards);
          }
        } catch (_) {}
      }
    }

    final result = await _apiClient.get<List<CatalogCard>>(
      path: ApiEndpoints.cards,
      queryParameters: query,
      fromJson: (data) {
        final list = (data is List) ? data : (data['items'] as List? ?? []);
        return list.map((e) => CatalogCardModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );

    if (result.isSuccess) {
      if (page == 1 && search == null && bankSlug == null) {
        final rawList = (result as ApiSuccess<List<CatalogCard>>)
            .data
            .map((c) => (c as CatalogCardModel).toJson())
            .toList();
        _cacheService.setCatalogCache(jsonEncode(rawList));
      }
      return result;
    }

    // Offline / Mock fallback filter
    var filtered = List<CatalogCardModel>.from(MockSeedData.sampleCards);
    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(search.toLowerCase()) ||
              c.bankName.toLowerCase().contains(search.toLowerCase()) ||
              c.keyPerks.any((p) => p.toLowerCase().contains(search.toLowerCase())))
          .toList();
    }
    if (bankSlug != null && bankSlug.isNotEmpty) {
      filtered = filtered.where((c) => c.bankSlug == bankSlug).toList();
    }
    if (network != null && network.isNotEmpty) {
      filtered = filtered.where((c) => c.network.toLowerCase().contains(network.toLowerCase())).toList();
    }
    if (isPopular == true) {
      filtered = filtered.where((c) => c.isPopular).toList();
    }
    if (feeType == 'free') {
      filtered = filtered.where((c) => c.annualFee == 0).toList();
    } else if (feeType == 'lt1k') {
      filtered = filtered.where((c) => c.annualFee > 0 && c.annualFee <= 1000).toList();
    } else if (feeType == '1k5k') {
      filtered = filtered.where((c) => c.annualFee > 1000 && c.annualFee <= 5000).toList();
    } else if (feeType == 'gt5k') {
      filtered = filtered.where((c) => c.annualFee > 5000).toList();
    }

    return ApiSuccess(filtered);
  }

  @override
  Future<ApiResult<CatalogCard>> getCardBySlug(String slug) async {
    final result = await _apiClient.get<CatalogCard>(
      path: ApiEndpoints.cardDetail(slug),
      fromJson: (data) => CatalogCardModel.fromJson(data as Map<String, dynamic>),
    );

    if (result.isSuccess) return result;

    // Fallback to mock cards
    final mock = MockSeedData.sampleCards.firstWhere(
      (c) => c.slug == slug,
      orElse: () => MockSeedData.sampleCards.first,
    );
    return ApiSuccess(mock);
  }

  @override
  Future<ApiResult<List<Bank>>> getBanks({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cacheService.getBanksCache();
      if (cached != null) {
        try {
          final List decoded = jsonDecode(cached) as List;
          return ApiSuccess(decoded.map((e) => BankModel.fromJson(e)).toList());
        } catch (_) {}
      }
    }

    final result = await _apiClient.get<List<Bank>>(
      path: ApiEndpoints.banks,
      fromJson: (data) => (data as List).map((e) => BankModel.fromJson(e as Map<String, dynamic>)).toList(),
    );

    if (result.isSuccess) {
      final list = (result as ApiSuccess<List<Bank>>)
          .data
          .map((b) => (b as BankModel).toJson())
          .toList();
      _cacheService.setBanksCache(jsonEncode(list));
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
          final List decoded = jsonDecode(cached) as List;
          return ApiSuccess(decoded.map((e) => CategoryModel.fromJson(e)).toList());
        } catch (_) {}
      }
    }

    final result = await _apiClient.get<List<SpendCategory>>(
      path: ApiEndpoints.categories,
      fromJson: (data) => (data as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList(),
    );

    if (result.isSuccess) {
      final list = (result as ApiSuccess<List<SpendCategory>>)
          .data
          .map((c) => (c as CategoryModel).toJson())
          .toList();
      _cacheService.setCategoriesCache(jsonEncode(list));
      return result;
    }

    return const ApiSuccess(MockSeedData.categories);
  }
}
