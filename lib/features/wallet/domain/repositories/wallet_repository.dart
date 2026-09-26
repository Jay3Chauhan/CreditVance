import '../../../../core/network/api_result.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../entities/user_card.dart';

/// Wallet metadata + hardware vault operations.
abstract class WalletRepository {
  Future<ApiResult<List<UserCard>>> getUserCards({bool forceRefresh = false});

  Future<ApiResult<UserCard>> addUserCard({
    required CatalogCard card,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  });

  Future<ApiResult<UserCard>> updateUserCard(
    UserCard card, {
    String? nickname,
    int? billingCycleDay,
  });

  Future<ApiResult<bool>> deleteUserCard(int userCardId);

  Future<void> saveOrder(List<int> orderedIds);

  Future<List<UserCard>> loadSampleCards();

  Future<VaultStatus> copyCardNumber(int userCardId, {required Duration clearAfter});

  Future<VaultStatus> copyField(int userCardId, String field, {required Duration clearAfter});

  Future<(VaultStatus, VaultSecrets?)> readSecrets(int userCardId);

  Future<void> clearLocalWallet();
}
