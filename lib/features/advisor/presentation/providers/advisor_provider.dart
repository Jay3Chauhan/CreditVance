import 'package:flutter/foundation.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/repositories/advisor_repository.dart';

/// Provider for Smart Advisor "Which Card Should I Use?" feature.
/// Strictly Zero setState: Uses Provider & ChangeNotifier.
class AdvisorProvider extends ChangeNotifier {
  final AdvisorRepository _repository;

  AdvisorProvider(this._repository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  String _selectedCategory = 'dining';
  String get selectedCategory => _selectedCategory;

  double _spendAmount = 5000.0;
  double get spendAmount => _spendAmount;

  bool _isInternational = false;
  bool get isInternational => _isInternational;

  AdvisorRecommendation? _recommendation;
  AdvisorRecommendation? get recommendation => _recommendation;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Initial fetch
  Future<void> init() async {
    if (_recommendation != null) return;
    await fetchRecommendation();
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    _setState(ViewState.refreshing);
    await fetchRecommendation();
  }

  void setCategory(String slug) {
    if (_selectedCategory == slug) return;
    _selectedCategory = slug;
    fetchRecommendation();
  }

  void setSpendAmount(double amount) {
    _spendAmount = amount;
    fetchRecommendation();
  }

  void setInternational(bool val) {
    if (_isInternational == val) return;
    _isInternational = val;
    fetchRecommendation();
  }

  Future<void> fetchRecommendation() async {
    _setState(ViewState.loading);

    final result = await _repository.getRecommendation(
      categorySlug: _selectedCategory,
      spendAmount: _spendAmount,
      isInternational: _isInternational,
    );

    result.when(
      success: (rec) {
        _recommendation = rec;
        _errorMessage = null;
        _setState(ViewState.loaded);
      },
      failure: (message, statusCode) {
        _errorMessage = message;
        _setState(ViewState.error);
      },
    );
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
}
