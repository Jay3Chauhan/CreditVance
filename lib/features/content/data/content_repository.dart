import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../catalog/data/models/catalog_card_model.dart';
import '../../catalog/domain/entities/catalog_card.dart';
import '../domain/content_models.dart';

/// Public content platform: home, banners, promotions, compare, search
/// suggestions, shortlist, insights, FAQ and legal links.
class ContentRepository {
  final ApiClient _api;

  ContentRepository(this._api);

  Future<ApiResult<HomeFeed>> home() {
    return _api.get<HomeFeed>(
      path: ApiEndpoints.home,
      fromJson: (data) => _home(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<AppBanner>>> banners({required String placement, String? audience}) {
    return _api.get<List<AppBanner>>(
      path: ApiEndpoints.banners,
      queryParameters: {
        'placement': placement,
        'audience': ?audience,
      },
      fromJson: (data) => _list(data).map((e) => AppBanner.fromJson(e)).toList(),
    );
  }

  Future<ApiResult<List<Promotion>>> promotions({String? cardSlug, bool? featured}) {
    return _api.get<List<Promotion>>(
      path: ApiEndpoints.promotions,
      queryParameters: {
        'card_slug': ?cardSlug,
        if (featured == true) 'featured': true,
      },
      fromJson: (data) => _list(data).map((e) => Promotion.fromJson(e)).toList(),
    );
  }

  Future<ApiResult<Promotion>> promotion(String slug) {
    return _api.get<Promotion>(
      path: ApiEndpoints.promotion(slug),
      fromJson: (data) => Promotion.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<CardCompareResult>> compare(List<String> slugs) {
    return _api.post<CardCompareResult>(
      path: ApiEndpoints.compare,
      data: {'slugs': slugs},
      fromJson: (data) {
        final map = data as Map<String, dynamic>;
        Map<String, num?> values(dynamic raw) {
          if (raw is! Map) return const {};
          return raw.map((k, v) => MapEntry(k.toString(), v is num ? v : num.tryParse('$v')));
        }

        final rows = (map['rows'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((r) => CompareRow(
                  key: r['key'] as String? ?? '',
                  label: r['label'] as String? ?? '',
                  better: r['better'] as String? ?? 'higher',
                  values: values(r['values']),
                  winnerSlug: r['winner_slug'] as String?,
                ))
            .toList();
        final rates = (map['category_rates'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((r) => CompareCategoryRate(
                  categorySlug: r['category_slug'] as String? ?? '',
                  rates: values(r['rates']),
                  winnerSlug: r['winner_slug'] as String?,
                ))
            .toList();
        return CardCompareResult(rows: rows, categoryRates: rates);
      },
    );
  }

  Future<ApiResult<List<SearchSuggestion>>> suggest(String query, {int limit = 8}) {
    return _api.get<List<SearchSuggestion>>(
      path: ApiEndpoints.searchSuggest,
      queryParameters: {'q': query, 'limit': limit},
      fromJson: (data) => _list(data).map((e) => SearchSuggestion.fromJson(e)).toList(),
    );
  }

  Future<ApiResult<List<CatalogCard>>> savedCards() {
    return _api.get<List<CatalogCard>>(
      path: ApiEndpoints.savedCards,
      fromJson: (data) => _list(data)
          .map((e) => CatalogCardModel.fromJson((e['card'] as Map<String, dynamic>?) ?? e))
          .toList(),
    );
  }

  Future<ApiResult<bool>> saveCard(int cardId) {
    return _api.post<bool>(
      path: ApiEndpoints.savedCards,
      data: {'card_id': cardId},
      fromJson: (_) => true,
    );
  }

  Future<ApiResult<bool>> unsaveCard(int cardId) {
    return _api.delete<bool>(
      path: ApiEndpoints.savedCard(cardId),
      fromJson: (_) => true,
    );
  }

  Future<ApiResult<WalletInsights>> walletInsights() {
    return _api.get<WalletInsights>(
      path: ApiEndpoints.walletInsights,
      fromJson: (data) {
        final map = data as Map<String, dynamic>;
        final due = map['next_due'];
        final picks = (map['category_picks'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((p) => CategoryPick(
                  categorySlug: p['category_slug'] as String? ?? '',
                  iconKey: p['icon_key'] as String?,
                  ratePercent: (p['rate_percent'] as num?)?.toDouble() ?? 0,
                  nickname: p['nickname'] as String?,
                ))
            .toList();
        return WalletInsights(
          cardCount: (map['card_count'] as num?)?.toInt() ?? 0,
          totalRenewalFee: (map['total_renewal_fee_inr'] as num?)?.toDouble() ?? 0,
          lifetimeFreeCount: (map['lifetime_free_count'] as num?)?.toInt() ?? 0,
          loungeCardCount: (map['lounge_card_count'] as num?)?.toInt() ?? 0,
          nextDue: due is Map<String, dynamic>
              ? DueReminder(
                  nickname: due['nickname'] as String? ?? '',
                  cardTitle: due['card_title'] as String? ?? '',
                  bankName: due['bank_name'] as String? ?? '',
                  daysUntilDue: (due['days_until_due'] as num?)?.toInt(),
                  message: due['message'] as String? ?? '',
                )
              : null,
          categoryPicks: picks,
          emptyMessage: map['empty_state_message'] as String?,
        );
      },
    );
  }

  Future<ApiResult<List<FaqItem>>> faq() {
    return _api.get<List<FaqItem>>(
      path: ApiEndpoints.faq,
      fromJson: (data) {
        final list = data is Map<String, dynamic> ? data['items'] ?? data['faqs'] : data;
        return _list(list).map((e) => FaqItem.fromJson(e)).toList();
      },
    );
  }

  Future<ApiResult<LegalLinks>> legal() {
    return _api.get<LegalLinks>(
      path: ApiEndpoints.legal,
      fromJson: (data) {
        final map = data as Map<String, dynamic>;
        return LegalLinks(
          privacyPolicyUrl: map['privacy_policy_url'] as String? ?? '',
          termsUrl: map['terms_of_service_url'] as String? ?? '',
          deletionUrl: map['data_deletion_policy_url'] as String?,
          contactEmail: map['contact_email'] as String?,
        );
      },
    );
  }

  Future<ApiResult<AppConfig>> config() {
    return _api.get<AppConfig>(
      path: ApiEndpoints.metaConfig,
      fromJson: (data) {
        final map = data as Map<String, dynamic>;
        return AppConfig(
          maintenanceMode: map['maintenance_mode'] as bool? ?? false,
          maintenanceMessage: map['maintenance_message'] as String?,
        );
      },
    );
  }

  /// Fire-and-forget impression / click tracking. Failures are ignored.
  Future<void> trackBanner(int id, String event) async {
    await _api.post<bool>(
      path: ApiEndpoints.bannerTrack(id),
      data: {'event': event},
      fromJson: (_) => true,
    );
  }

  Future<void> trackPromotion(int id, String event) async {
    await _api.post<bool>(
      path: ApiEndpoints.promotionTrack(id),
      data: {'event': event},
      fromJson: (_) => true,
    );
  }

  static HomeFeed _home(Map<String, dynamic> json) {
    List<AppBanner> banners(String key) =>
        (json[key] as List? ?? const []).whereType<Map<String, dynamic>>().map(AppBanner.fromJson).toList();
    List<CatalogCard> cards(dynamic raw) =>
        (raw as List? ?? const []).whereType<Map<String, dynamic>>().map(CatalogCardModel.fromJson).toList();

    final collections = (json['collections'] as List? ?? const []).whereType<Map<String, dynamic>>().map((c) {
      return HomeCollection(
        key: c['key'] as String? ?? '',
        title: c['title'] as String? ?? '',
        subtitle: c['subtitle'] as String?,
        action: ContentAction.fromJson(c['action'] as Map<String, dynamic>?),
        cards: cards(c['cards']),
      );
    }).toList();

    return HomeFeed(
      heroBanners: banners('hero_banners'),
      stripBanners: banners('strip_banners'),
      featuredPromotions: (json['featured_promotions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Promotion.fromJson)
          .toList(),
      popularCards: cards(json['popular_cards']),
      collections: collections,
      quickActions: (json['quick_actions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuickAction.fromJson)
          .toList(),
    );
  }

  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      for (final key in ['items', 'results', 'cards', 'faqs']) {
        final inner = data[key];
        if (inner is List) return inner.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }
}
