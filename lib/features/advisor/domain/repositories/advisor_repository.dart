import '../../../../core/network/api_result.dart';
import '../entities/recommendation.dart';

/// Contract for Smart Advisor recommendation engine
abstract class AdvisorRepository {
  Future<ApiResult<AdvisorRecommendation>> getRecommendation({
    required String categorySlug,
    required double spendAmount,
    bool isInternational = false,
  });
}
