import '../../../../core/network/api_result.dart';
import '../entities/recommendation.dart';

abstract class AdvisorRepository {
  Future<ApiResult<AdvisorRecommendation>> getRecommendation({
    required String categorySlug,
    required double spendAmount,
    String? merchantName,
    bool isInternational = false,
  });
}
