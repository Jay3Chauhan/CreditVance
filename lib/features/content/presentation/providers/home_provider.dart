import 'package:flutter/foundation.dart';

import '../../../../core/network/api_result.dart';
import '../../data/content_repository.dart';
import '../../domain/content_models.dart';

/// Server-driven content: home feed, placement banners, card promotions and
/// wallet insights. Everything here is optional decoration, so failures are
/// swallowed and the UI simply renders nothing.
class HomeProvider extends ChangeNotifier {
  final ContentRepository _repository;

  HomeProvider(this._repository);

  HomeFeed? feed;
  String? maintenanceMessage;
  bool loading = false;
  WalletInsights? walletInsights;

  final Map<String, List<AppBanner>> _banners = {};
  final Map<String, List<Promotion>> _cardPromos = {};

  Future<void> load() async {
    loading = feed == null;
    notifyListeners();
    final home = await _repository.home();
    final config = await _repository.config();
    if (home case ApiSuccess(:final data)) feed = data;
    if (config case ApiSuccess(:final data)) {
      maintenanceMessage = data.maintenanceMode ? (data.maintenanceMessage ?? 'Credvert is briefly under maintenance.') : null;
    }
    loading = false;
    notifyListeners();
  }

  List<AppBanner> bannersFor(String placement) => _banners[placement] ?? const [];

  Future<void> loadBanners(String placement, {String? audience, bool force = false}) async {
    if (_banners.containsKey(placement) && !force) return;
    _banners[placement] = const [];
    final result = await _repository.banners(placement: placement, audience: audience);
    _banners[placement] = result.dataOrNull ?? const [];
    if (_banners[placement]!.isNotEmpty) notifyListeners();
  }

  List<Promotion> promotionsForCard(String slug) => _cardPromos[slug] ?? const [];

  Future<void> loadCardPromotions(String slug) async {
    if (_cardPromos.containsKey(slug)) return;
    _cardPromos[slug] = const [];
    final result = await _repository.promotions(cardSlug: slug);
    final data = result.dataOrNull ?? const [];
    _cardPromos[slug] = data.where((p) => p.cardSlug == null || p.cardSlug == slug).toList();
    if (_cardPromos[slug]!.isNotEmpty) notifyListeners();
  }

  Future<void> loadWalletInsights() async {
    final result = await _repository.walletInsights();
    if (result case ApiSuccess(:final data)) {
      walletInsights = data;
      notifyListeners();
    }
  }

  void clearMemberContent() {
    walletInsights = null;
    _banners.remove('wallet');
    notifyListeners();
  }

  void trackBanner(AppBanner banner, String event) => _repository.trackBanner(banner.id, event);

  void trackPromotion(Promotion promo, String event) => _repository.trackPromotion(promo.id, event);
}
