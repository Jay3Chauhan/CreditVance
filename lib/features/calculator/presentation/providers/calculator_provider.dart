import 'package:flutter/foundation.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/calculation_result.dart';
import '../../domain/repositories/calculator_repository.dart';

/// Provider for Reward Calculator & Comparison Simulator.
/// Strictly Zero setState: Uses Provider & ChangeNotifier.
class CalculatorProvider extends ChangeNotifier {
  final CalculatorRepository _repository;

  CalculatorProvider(this._repository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  int _selectedCardId = 1;
  int get selectedCardId => _selectedCardId;

  double _monthlyDining = 10000.0;
  double get monthlyDining => _monthlyDining;

  double _monthlyFlights = 15000.0;
  double get monthlyFlights => _monthlyFlights;

  double _monthlyGrocery = 8000.0;
  double get monthlyGrocery => _monthlyGrocery;

  double _monthlyShopping = 12000.0;
  double get monthlyShopping => _monthlyShopping;

  double _monthlyOther = 10000.0;
  double get monthlyOther => _monthlyOther;

  CalculationResult? _result;
  CalculationResult? get result => _result;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    if (_result != null) return;
    await calculate();
  }

  Future<void> refresh() async {
    _setState(ViewState.refreshing);
    await calculate();
  }

  void setSelectedCard(int id) {
    if (_selectedCardId == id) return;
    _selectedCardId = id;
    calculate();
  }

  void updateSpend({
    double? dining,
    double? flights,
    double? grocery,
    double? shopping,
    double? other,
  }) {
    if (dining != null) _monthlyDining = dining;
    if (flights != null) _monthlyFlights = flights;
    if (grocery != null) _monthlyGrocery = grocery;
    if (shopping != null) _monthlyShopping = shopping;
    if (other != null) _monthlyOther = other;
    calculate();
  }

  Future<void> calculate() async {
    _setState(ViewState.loading);

    final res = await _repository.calculateAnnualRewards(
      cardId: _selectedCardId,
      monthlyDining: _monthlyDining,
      monthlyFlights: _monthlyFlights,
      monthlyGrocery: _monthlyGrocery,
      monthlyShopping: _monthlyShopping,
      monthlyOther: _monthlyOther,
    );

    res.when(
      success: (data) {
        _result = data;
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
