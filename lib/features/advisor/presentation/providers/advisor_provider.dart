import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/view_state.dart';
import '../../../wallet/domain/entities/user_card.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/repositories/advisor_repository.dart';
import '../../domain/wallet_ranker.dart';

/// "Which card should I use?" — debounced, race-safe recommendations that
/// merge the server's market benchmark with an on-device wallet ranking.
class AdvisorProvider extends ChangeNotifier {
  final AdvisorRepository _repository;

  AdvisorProvider(this._repository);

  static const List<double> quickAmounts = [500, 2000, 5000, 10000, 25000];

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  String _category = 'Dining';
  String get selectedCategory => _category;

  double _spendAmount = 2000;
  double get spendAmount => _spendAmount;

  bool _isInternational = false;
  bool get isInternational => _isInternational;

  AdvisorRecommendation? _recommendation;
  AdvisorRecommendation? get recommendation => _recommendation;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<UserCard> _wallet = const [];
  bool _useLocalRanking = true;
  String _walletSignature = '';

  Timer? _debounce;
  int _seq = 0;

  /// Wired via ProxyProvider whenever the wallet or auth mode changes.
  void updateWallet(List<UserCard> cards, {required bool isGuest}) {
    final signature = '${isGuest ? 'g' : 's'}:${cards.map((c) => c.id).join(',')}';
    if (signature == _walletSignature) return;
    _walletSignature = signature;
    _wallet = cards;
    _useLocalRanking = isGuest;
    if (_state != ViewState.initial) _schedule(immediate: true);
  }

  Future<void> init() async {
    if (_state != ViewState.initial) return;
    await _fetch();
  }

  Future<void> refresh() async {
    _state = ViewState.refreshing;
    notifyListeners();
    await _fetch();
  }

  void setCategory(String slug) {
    if (_category == slug) return;
    _category = slug;
    notifyListeners();
    _schedule(immediate: true);
  }

  void setSpendAmount(double amount) {
    if (amount == _spendAmount || amount <= 0) return;
    _spendAmount = amount;
    notifyListeners();
    _schedule();
  }

  void setInternational(bool value) {
    if (_isInternational == value) return;
    _isInternational = value;
    notifyListeners();
    _schedule(immediate: true);
  }

  void _schedule({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      _fetch();
    } else {
      _debounce = Timer(AppDimensions.debounce, _fetch);
    }
  }

  Future<void> _fetch() async {
    final seq = ++_seq;
    if (_recommendation == null) {
      _state = ViewState.loading;
    } else if (_state != ViewState.refreshing) {
      _state = ViewState.refreshing;
    }
    notifyListeners();

    final result = await _repository.getRecommendation(
      categorySlug: _category,
      spendAmount: _spendAmount,
      isInternational: _isInternational,
    );
    if (seq != _seq) return;

    final local = WalletRanker.rank(_wallet, spend: _spendAmount, isInternational: _isInternational);

    switch (result) {
      case ApiSuccess(:final data):
        var rec = data;
        if ((_useLocalRanking || !rec.hasWalletPick) && local.isNotEmpty) {
          rec = rec.copyWith(
            topCard: local.first,
            alternatives: local.skip(1).toList(),
            insights: rec.insights.where((i) => !i.toLowerCase().contains("haven't added")).toList(),
            source: RecommendationSource.onDevice,
          );
        }
        _recommendation = rec;
        _errorMessage = null;
        _state = ViewState.loaded;
      case ApiFailure(:final message):
        if (local.isNotEmpty) {
          _recommendation = AdvisorRecommendation(
            categorySlug: _category,
            spendAmount: _spendAmount,
            isInternational: _isInternational,
            topCard: local.first,
            alternatives: local.skip(1).toList(),
            insights: const ['Offline — ranked on your device using base reward rates.'],
            source: RecommendationSource.onDevice,
          );
          _errorMessage = null;
          _state = ViewState.loaded;
        } else {
          _errorMessage = message;
          _state = _recommendation == null ? ViewState.error : ViewState.loaded;
        }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
