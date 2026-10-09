import '../../../../core/network/api_result.dart';
import '../entities/bank.dart';
import '../entities/card_tab.dart';
import '../entities/catalog_card.dart';
import '../entities/category.dart';

/// Catalog query filters. Network uses backend codes (VISA, MASTERCARD, RUPAY, AMEX).
class CatalogQuery {
  final String? search;
  final String? bankSlug;
  final String? network;
  final String? feeType;
  final bool popularOnly;
  final bool? hasLounge;
  final String? loungeType;
  final String sortBy;

  const CatalogQuery({
    this.search,
    this.bankSlug,
    this.network,
    this.feeType,
    this.popularOnly = false,
    this.hasLounge,
    this.loungeType,
    this.sortBy = 'popular',
  });

  bool get isDefault =>
      (search == null || search!.isEmpty) &&
      bankSlug == null &&
      network == null &&
      feeType == null &&
      !popularOnly &&
      hasLounge == null &&
      loungeType == null &&
      sortBy == 'popular';

  int get activeFilterCount =>
      (bankSlug != null ? 1 : 0) +
      (network != null ? 1 : 0) +
      (feeType != null ? 1 : 0) +
      (popularOnly ? 1 : 0) +
      (hasLounge != null ? 1 : 0) +
      (loungeType != null ? 1 : 0) +
      (sortBy != 'popular' ? 1 : 0);

  CatalogQuery copyWith({
    String? search,
    Object? bankSlug = _keep,
    Object? network = _keep,
    Object? feeType = _keep,
    bool? popularOnly,
    Object? hasLounge = _keep,
    Object? loungeType = _keep,
    String? sortBy,
  }) {
    return CatalogQuery(
      search: search ?? this.search,
      bankSlug: identical(bankSlug, _keep) ? this.bankSlug : bankSlug as String?,
      network: identical(network, _keep) ? this.network : network as String?,
      feeType: identical(feeType, _keep) ? this.feeType : feeType as String?,
      popularOnly: popularOnly ?? this.popularOnly,
      hasLounge: identical(hasLounge, _keep) ? this.hasLounge : hasLounge as bool?,
      loungeType: identical(loungeType, _keep) ? this.loungeType : loungeType as String?,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  static const Object _keep = Object();
}

abstract class CatalogRepository {
  Future<ApiResult<PagedResult<CatalogCard>>> getCards({
    CatalogQuery query = const CatalogQuery(),
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });

  Future<ApiResult<CatalogCard>> getCardBySlug(String slug);

  Future<ApiResult<CardTab>> getCardTab(String slug, String tabName);

  Future<ApiResult<List<Bank>>> getBanks({bool forceRefresh = false});

  Future<ApiResult<List<SpendCategory>>> getCategories({bool forceRefresh = false});

  Future<void> clearCache();
}
