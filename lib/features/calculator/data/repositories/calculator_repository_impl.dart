import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/calculation_result.dart';
import '../../domain/repositories/calculator_repository.dart';
import '../models/calculation_result_model.dart';

/// Implementation of CalculatorRepository with offline mathematical financial engine
class CalculatorRepositoryImpl implements CalculatorRepository {
  final ApiClient _apiClient;

  CalculatorRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<ApiResult<CalculationResult>> calculateAnnualRewards({
    required int cardId,
    required double monthlyDining,
    required double monthlyFlights,
    required double monthlyGrocery,
    required double monthlyShopping,
    required double monthlyOther,
  }) async {
    final payload = {
      'card_id': cardId,
      'monthly_dining': monthlyDining,
      'monthly_flights': monthlyFlights,
      'monthly_grocery': monthlyGrocery,
      'monthly_shopping': monthlyShopping,
      'monthly_other': monthlyOther,
    };

    final result = await _apiClient.post<CalculationResult>(
      path: ApiEndpoints.calculator,
      data: payload,
      fromJson: (data) => CalculationResultModel.fromJson(data as Map<String, dynamic>),
    );

    if (result.isSuccess) return result;

    // Accurate Local Simulation Engine
    final card = MockSeedData.sampleCards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => MockSeedData.sampleCards.first,
    );

    final annualDining = monthlyDining * 12;
    final annualFlights = monthlyFlights * 12;
    final annualGrocery = monthlyGrocery * 12;
    final annualShopping = monthlyShopping * 12;
    final annualOther = monthlyOther * 12;

    final totalAnnualSpend =
        annualDining + annualFlights + annualGrocery + annualShopping + annualOther;

    double diningRate = card.baseReturnRate;
    double flightRate = card.baseReturnRate;
    double groceryRate = card.baseReturnRate;
    double shoppingRate = card.baseReturnRate;
    double otherRate = card.baseReturnRate;

    if (card.slug.contains('infinia')) {
      diningRate = 10.0;
      flightRate = 16.5;
      shoppingRate = 3.3;
      groceryRate = 3.3;
      otherRate = 3.3;
    } else if (card.slug.contains('sbi-cashback')) {
      diningRate = 5.0;
      flightRate = 5.0;
      shoppingRate = 5.0;
      groceryRate = 5.0;
      otherRate = 1.0;
    } else if (card.slug.contains('atlas')) {
      flightRate = 10.0;
      diningRate = 4.0;
      shoppingRate = 4.0;
      groceryRate = 4.0;
      otherRate = 4.0;
    } else if (card.slug.contains('amazon-pay')) {
      shoppingRate = 5.0;
      diningRate = 2.0;
      groceryRate = 2.0;
      flightRate = 2.0;
      otherRate = 1.0;
    }

    final diningEarned = (annualDining * (diningRate / 100)).roundToDouble();
    final flightEarned = (annualFlights * (flightRate / 100)).roundToDouble();
    final groceryEarned = (annualGrocery * (groceryRate / 100)).roundToDouble();
    final shoppingEarned = (annualShopping * (shoppingRate / 100)).roundToDouble();
    final otherEarned = (annualOther * (otherRate / 100)).roundToDouble();

    final totalRewardValue =
        diningEarned + flightEarned + groceryEarned + shoppingEarned + otherEarned;

    // Fee waiver check
    double applicableFee = card.annualFee;
    if (card.feeWaiverSpend != null && totalAnnualSpend >= card.feeWaiverSpend!) {
      applicableFee = 0.0; // Waived!
    }

    final netBenefit = totalRewardValue - applicableFee;
    final effectiveRoi = totalAnnualSpend > 0 ? (netBenefit / totalAnnualSpend) * 100 : 0.0;

    final breakdowns = [
      CategoryRewardBreakdown(
        categoryName: 'Flight Bookings',
        spend: annualFlights,
        returnPercentage: flightRate,
        earnedRupees: flightEarned,
      ),
      CategoryRewardBreakdown(
        categoryName: 'Dining & Outings',
        spend: annualDining,
        returnPercentage: diningRate,
        earnedRupees: diningEarned,
      ),
      CategoryRewardBreakdown(
        categoryName: 'Online Shopping',
        spend: annualShopping,
        returnPercentage: shoppingRate,
        earnedRupees: shoppingEarned,
      ),
      CategoryRewardBreakdown(
        categoryName: 'Groceries',
        spend: annualGrocery,
        returnPercentage: groceryRate,
        earnedRupees: groceryEarned,
      ),
      CategoryRewardBreakdown(
        categoryName: 'General Spends',
        spend: annualOther,
        returnPercentage: otherRate,
        earnedRupees: otherEarned,
      ),
    ];

    return ApiSuccess(
      CalculationResult(
        cardId: card.id,
        cardName: card.name,
        bankName: card.bankName,
        annualSpend: totalAnnualSpend,
        annualFee: applicableFee,
        totalRewardValue: totalRewardValue,
        netBenefit: netBenefit,
        effectiveRoi: effectiveRoi,
        breakdowns: breakdowns,
      ),
    );
  }
}
