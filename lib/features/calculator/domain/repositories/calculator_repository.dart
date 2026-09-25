import '../../../../core/network/api_result.dart';
import '../entities/calculation_result.dart';

/// Contract for Reward Calculator engine
abstract class CalculatorRepository {
  Future<ApiResult<CalculationResult>> calculateAnnualRewards({
    required int cardId,
    required double monthlyDining,
    required double monthlyFlights,
    required double monthlyGrocery,
    required double monthlyShopping,
    required double monthlyOther,
  });
}
