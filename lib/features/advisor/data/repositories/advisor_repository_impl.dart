import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/repositories/advisor_repository.dart';
import '../models/recommendation_model.dart';

class AdvisorRepositoryImpl implements AdvisorRepository {
  final ApiClient _apiClient;

  AdvisorRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<ApiResult<AdvisorRecommendation>> getRecommendation({
    required String categorySlug,
    required double spendAmount,
    String? merchantName,
    bool isInternational = false,
  }) {
    return _apiClient.post<AdvisorRecommendation>(
      path: ApiEndpoints.advisorRecommend,
      data: {
        'category_slug': categorySlug,
        'spend_amount': spendAmount,
        if (merchantName != null && merchantName.isNotEmpty) 'merchant_name': merchantName,
        'is_international': isInternational,
      },
      fromJson: (data) => AdvisorRecommendationModel.fromJson(
        data as Map<String, dynamic>,
        isInternational: isInternational,
      ),
    );
  }
}
