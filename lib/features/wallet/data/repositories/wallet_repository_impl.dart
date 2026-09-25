import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../domain/entities/user_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/user_card_model.dart';

/// Implementation of WalletRepository adhering to Zero-Knowledge security
class WalletRepositoryImpl implements WalletRepository {
  final ApiClient _apiClient;
  final SecureVaultService _vaultService;

  // In-memory cache for offline resiliency
  final List<UserCardModel> _localPortfolio = [
    const UserCardModel(
      id: 101,
      cardId: 1,
      nickname: 'Primary Infinia',
      last4Digits: '9012',
      billingCycleDay: 15,
      cardName: 'HDFC Infinia Metal Edition',
      bankName: 'HDFC Bank',
      network: 'Visa Infinite',
      annualFee: 12500,
      hasVaultDetails: true,
    ),
    const UserCardModel(
      id: 102,
      cardId: 2,
      nickname: 'Shopping Card',
      last4Digits: '4321',
      billingCycleDay: 5,
      cardName: 'SBI Cashback Credit Card',
      bankName: 'SBI Card',
      network: 'Mastercard World',
      annualFee: 999,
      hasVaultDetails: true,
    ),
    const UserCardModel(
      id: 103,
      cardId: 3,
      nickname: 'Travel Card',
      last4Digits: '7765',
      billingCycleDay: 20,
      cardName: 'Axis Bank Atlas Credit Card',
      bankName: 'Axis Bank',
      network: 'Visa Signature',
      annualFee: 5000,
      hasVaultDetails: true,
    ),
  ];

  WalletRepositoryImpl({
    required ApiClient apiClient,
    required SecureVaultService vaultService,
  })  : _apiClient = apiClient,
        _vaultService = vaultService {
    // Seed initial vault PANs for offline demo experience
    _vaultService.saveLocalCardDetails(
      userCardId: 101,
      cardNumber: '4532 9812 3456 9012',
      cvv: '889',
      expiry: '12/28',
    );
    _vaultService.saveLocalCardDetails(
      userCardId: 102,
      cardNumber: '5412 7534 8901 4321',
      cvv: '412',
      expiry: '09/27',
    );
    _vaultService.saveLocalCardDetails(
      userCardId: 103,
      cardNumber: '4111 2222 3333 7765',
      cvv: '123',
      expiry: '04/29',
    );
  }

  @override
  Future<ApiResult<List<UserCard>>> getUserCards({bool forceRefresh = false}) async {
    final result = await _apiClient.get<List<UserCard>>(
      path: ApiEndpoints.userCards,
      fromJson: (data) {
        final list = (data is List) ? data : (data['items'] as List? ?? []);
        return list.map((e) => UserCardModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );

    if (result.isSuccess) {
      final cards = result.dataOrNull ?? [];
      final enrichedCards = <UserCard>[];
      for (final card in cards) {
        final hasDetails = await _vaultService.hasLocalDetails(card.id);
        enrichedCards.add(card.copyWith(hasVaultDetails: hasDetails));
      }
      return ApiSuccess(enrichedCards);
    }

    // Offline / Mock fallback
    final list = <UserCard>[];
    for (final card in _localPortfolio) {
      final hasDetails = await _vaultService.hasLocalDetails(card.id);
      list.add(card.copyWith(hasVaultDetails: hasDetails));
    }
    return ApiSuccess(list);
  }

  @override
  Future<ApiResult<UserCard>> addUserCard({
    required int cardId,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  }) async {
    // 1. Post NON-SENSITIVE metadata to backend
    final payload = {
      'card_id': cardId,
      'nickname': nickname,
      'last_4_digits': last4Digits,
      'billing_cycle_day': billingCycleDay,
    };

    final result = await _apiClient.post<UserCard>(
      path: ApiEndpoints.userCards,
      data: payload,
      fromJson: (data) => UserCardModel.fromJson(data as Map<String, dynamic>),
    );

    int userCardId;
    UserCard userCard;

    if (result.isSuccess) {
      userCard = result.dataOrNull!;
      userCardId = userCard.id;
    } else {
      // Offline fallback: generate mock card entry
      final catalogCard = MockSeedData.sampleCards.firstWhere(
        (c) => c.id == cardId,
        orElse: () => MockSeedData.sampleCards.first,
      );
      userCardId = DateTime.now().millisecondsSinceEpoch % 100000;
      final newCard = UserCardModel(
        id: userCardId,
        cardId: cardId,
        nickname: nickname,
        last4Digits: last4Digits,
        billingCycleDay: billingCycleDay,
        cardName: catalogCard.name,
        bankName: catalogCard.bankName,
        network: catalogCard.network,
        annualFee: catalogCard.annualFee,
        hasVaultDetails: fullCardNumber != null && fullCardNumber.isNotEmpty,
      );
      _localPortfolio.add(newCard);
      userCard = newCard;
    }

    // 2. Zero-Knowledge: Save full card PAN & CVV strictly into local hardware vault
    if (fullCardNumber != null && fullCardNumber.isNotEmpty) {
      await _vaultService.saveLocalCardDetails(
        userCardId: userCardId,
        cardNumber: fullCardNumber,
        cvv: cvv,
        expiry: expiry,
      );
    }

    return ApiSuccess(userCard.copyWith(hasVaultDetails: fullCardNumber != null && fullCardNumber.isNotEmpty));
  }

  @override
  Future<ApiResult<UserCard>> updateUserCard(
    int userCardId, {
    String? nickname,
    String? last4Digits,
  }) async {
    final payload = <String, dynamic>{};
    if (nickname != null) payload['nickname'] = nickname;
    if (last4Digits != null) payload['last_4_digits'] = last4Digits;

    final result = await _apiClient.patch<UserCard>(
      path: ApiEndpoints.userCardById(userCardId),
      data: payload,
      fromJson: (data) => UserCardModel.fromJson(data as Map<String, dynamic>),
    );

    if (result.isSuccess) return result;

    // Offline fallback update
    final index = _localPortfolio.indexWhere((c) => c.id == userCardId);
    if (index != -1) {
      final existing = _localPortfolio[index];
      final updated = UserCardModel(
        id: existing.id,
        cardId: existing.cardId,
        nickname: nickname ?? existing.nickname,
        last4Digits: last4Digits ?? existing.last4Digits,
        billingCycleDay: existing.billingCycleDay,
        cardName: existing.cardName,
        bankName: existing.bankName,
        network: existing.network,
        annualFee: existing.annualFee,
        imageUrl: existing.imageUrl,
        hasVaultDetails: existing.hasVaultDetails,
      );
      _localPortfolio[index] = updated;
      return ApiSuccess(updated);
    }

    return const ApiFailure('Card not found');
  }

  @override
  Future<ApiResult<bool>> deleteUserCard(int userCardId) async {
    await _apiClient.delete<bool>(
      path: ApiEndpoints.userCardById(userCardId),
      fromJson: (_) => true,
    );

    // Delete sensitive details from local vault
    await _vaultService.deleteLocalCardDetails(userCardId);
    _localPortfolio.removeWhere((c) => c.id == userCardId);

    return const ApiSuccess(true);
  }

  @override
  Future<bool> copyCardNumberWithBiometrics(int userCardId) {
    return _vaultService.copyCardNumberWithBiometrics(userCardId);
  }

  @override
  Future<Map<String, String>?> getCardDetailsWithBiometrics(int userCardId) {
    return _vaultService.getCardDetailsWithBiometrics(userCardId);
  }
}
