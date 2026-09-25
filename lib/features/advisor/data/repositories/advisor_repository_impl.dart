import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/repositories/advisor_repository.dart';
import '../models/recommendation_model.dart';

/// Implementation of AdvisorRepository with online endpoint and intelligent offline fallback
class AdvisorRepositoryImpl implements AdvisorRepository {
  final ApiClient _apiClient;

  AdvisorRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<ApiResult<AdvisorRecommendation>> getRecommendation({
    required String categorySlug,
    required double spendAmount,
    bool isInternational = false,
  }) async {
    final payload = {
      'category_slug': categorySlug,
      'spend_amount': spendAmount,
      'is_international': isInternational,
    };

    final result = await _apiClient.post<AdvisorRecommendation>(
      path: ApiEndpoints.advisorRecommend,
      data: payload,
      fromJson: (data) => AdvisorRecommendationModel.fromJson(data as Map<String, dynamic>),
    );

    if (result.isSuccess) return result;

    // Intelligent Offline Recommendation Engine
    final rec = _computeOfflineRecommendation(
      categorySlug: categorySlug,
      spendAmount: spendAmount,
      isInternational: isInternational,
    );

    return ApiSuccess(rec);
  }

  AdvisorRecommendation _computeOfflineRecommendation({
    required String categorySlug,
    required double spendAmount,
    required bool isInternational,
  }) {
    if (isInternational) {
      return AdvisorRecommendation(
        categorySlug: categorySlug,
        categoryName: 'International Forex',
        spendAmount: spendAmount,
        isInternational: true,
        topCard: RecommendationOption(
          cardId: 1,
          cardName: 'HDFC Infinia Metal Edition',
          bankName: 'HDFC Bank',
          network: 'Visa Infinite',
          returnPercentage: 3.3,
          estimatedValue: (spendAmount * 0.033).roundToDouble(),
          rewardType: 'Reward Points',
          reason: 'Low 2.0% forex markup completely offset by 3.3% base reward return.',
        ),
        runnersUp: [
          RecommendationOption(
            cardId: 3,
            cardName: 'Axis Bank Atlas Credit Card',
            bankName: 'Axis Bank',
            network: 'Visa Signature',
            returnPercentage: 4.0,
            estimatedValue: (spendAmount * 0.04).roundToDouble(),
            rewardType: 'EDGE Miles',
            reason: 'Earn 2 EDGE Miles per ₹100 on overseas transactions.',
          ),
        ],
      );
    }

    switch (categorySlug.toLowerCase()) {
      case 'dining':
        return AdvisorRecommendation(
          categorySlug: 'dining',
          categoryName: 'Dining & Food Delivery',
          spendAmount: spendAmount,
          isInternational: false,
          topCard: RecommendationOption(
            cardId: 1,
            cardName: 'HDFC Infinia Metal Edition',
            bankName: 'HDFC Bank',
            network: 'Visa Infinite',
            returnPercentage: 10.0,
            estimatedValue: (spendAmount * 0.10).roundToDouble(),
            rewardType: 'Reward Points',
            reason: 'Earn 5X-10X Points on Swiggy Dineout & ITC Hotels (up to 33% value).',
          ),
          runnersUp: [
            RecommendationOption(
              cardId: 2,
              cardName: 'SBI Cashback Credit Card',
              bankName: 'SBI Card',
              network: 'Mastercard World',
              returnPercentage: 5.0,
              estimatedValue: (spendAmount * 0.05).roundToDouble(),
              rewardType: 'Direct Cashback',
              reason: '5% direct statement cashback on Zomato & Swiggy online orders.',
            ),
          ],
        );

      case 'flights':
        return AdvisorRecommendation(
          categorySlug: 'flights',
          categoryName: 'Flight Bookings',
          spendAmount: spendAmount,
          isInternational: false,
          topCard: RecommendationOption(
            cardId: 1,
            cardName: 'HDFC Infinia Metal Edition',
            bankName: 'HDFC Bank',
            network: 'Visa Infinite',
            returnPercentage: 16.5,
            estimatedValue: (spendAmount * 0.165).roundToDouble(),
            rewardType: 'Reward Points',
            reason: '5X SmartBuy Flight Multiplier giving 16.5% return (1 pt = ₹1).',
          ),
          runnersUp: [
            RecommendationOption(
              cardId: 3,
              cardName: 'Axis Bank Atlas Credit Card',
              bankName: 'Axis Bank',
              network: 'Visa Signature',
              returnPercentage: 10.0,
              estimatedValue: (spendAmount * 0.10).roundToDouble(),
              rewardType: 'EDGE Miles',
              reason: '5 EDGE Miles per ₹100 direct with airlines, 1:2 airline transfer.',
            ),
          ],
        );

      case 'grocery':
        return AdvisorRecommendation(
          categorySlug: 'grocery',
          categoryName: 'Groceries & Supermarkets',
          spendAmount: spendAmount,
          isInternational: false,
          topCard: RecommendationOption(
            cardId: 6,
            cardName: 'Tata Neu Infinity HDFC Bank',
            bankName: 'HDFC Bank',
            network: 'RuPay / Visa',
            returnPercentage: 10.0,
            estimatedValue: (spendAmount * 0.10).roundToDouble(),
            rewardType: 'NeuCoins',
            reason: '10% NeuCoins on BigBasket purchases via Tata Neu ecosystem.',
          ),
          runnersUp: [
            RecommendationOption(
              cardId: 2,
              cardName: 'SBI Cashback Credit Card',
              bankName: 'SBI Card',
              network: 'Mastercard World',
              returnPercentage: 5.0,
              estimatedValue: (spendAmount * 0.05).roundToDouble(),
              rewardType: 'Direct Cashback',
              reason: '5% cashback on Blinkit, Zepto, and Instamart.',
            ),
          ],
        );

      default:
        return AdvisorRecommendation(
          categorySlug: categorySlug,
          categoryName: 'Online & Retail Shopping',
          spendAmount: spendAmount,
          isInternational: false,
          topCard: RecommendationOption(
            cardId: 2,
            cardName: 'SBI Cashback Credit Card',
            bankName: 'SBI Card',
            network: 'Mastercard World',
            returnPercentage: 5.0,
            estimatedValue: (spendAmount * 0.05).roundToDouble(),
            rewardType: 'Direct Cashback',
            reason: '5% flat statement cashback across all online e-commerce transactions.',
          ),
          runnersUp: [
            RecommendationOption(
              cardId: 4,
              cardName: 'ICICI Amazon Pay Credit Card',
              bankName: 'ICICI Bank',
              network: 'Visa Platinum',
              returnPercentage: 5.0,
              estimatedValue: (spendAmount * 0.05).roundToDouble(),
              rewardType: 'Amazon Pay Balance',
              reason: '5% unlimited cashback for Amazon Prime members with zero annual fee.',
            ),
            RecommendationOption(
              cardId: 1,
              cardName: 'HDFC Infinia Metal Edition',
              bankName: 'HDFC Bank',
              network: 'Visa Infinite',
              returnPercentage: 3.3,
              estimatedValue: (spendAmount * 0.033).roundToDouble(),
              rewardType: 'Reward Points',
              reason: '3.3% flat base reward rate on general retail merchants.',
            ),
          ],
        );
    }
  }
}
