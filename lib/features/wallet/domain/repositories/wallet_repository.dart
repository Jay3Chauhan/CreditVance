import '../../../../core/network/api_result.dart';
import '../entities/user_card.dart';

/// Contract for User Wallet and Secure Vault operations
abstract class WalletRepository {
  Future<ApiResult<List<UserCard>>> getUserCards({bool forceRefresh = false});

  Future<ApiResult<UserCard>> addUserCard({
    required int cardId,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  });

  Future<ApiResult<UserCard>> updateUserCard(
    int userCardId, {
    String? nickname,
    String? last4Digits,
  });

  Future<ApiResult<bool>> deleteUserCard(int userCardId);

  Future<bool> copyCardNumberWithBiometrics(int userCardId);

  Future<Map<String, String>?> getCardDetailsWithBiometrics(int userCardId);
}
