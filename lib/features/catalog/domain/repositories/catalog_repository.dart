import '../../../../core/network/api_result.dart';
import '../entities/bank.dart';
import '../entities/catalog_card.dart';
import '../entities/category.dart';

/// Contract for Catalog operations
abstract class CatalogRepository {
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
  });

  Future<ApiResult<CatalogCard>> getCardBySlug(String slug);

  Future<ApiResult<List<Bank>>> getBanks({bool forceRefresh = false});

  Future<ApiResult<List<SpendCategory>>> getCategories({bool forceRefresh = false});
}
