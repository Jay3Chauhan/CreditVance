import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../domain/entities/user_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/user_card_model.dart';

/// Wallet repository.
///
/// * Signed-in users: metadata (nickname, last 4, billing day) syncs with the
///   backend; a local copy keeps the wallet usable offline.
/// * Guests: everything stays on device.
/// * Secrets (PAN / CVV / expiry) always stay in [SecureVaultService].
class WalletRepositoryImpl implements WalletRepository {
  final ApiClient _apiClient;
  final SecureVaultService _vault;
  final LocalCacheService _cache;

  WalletRepositoryImpl({
    required ApiClient apiClient,
    required SecureVaultService vaultService,
    required LocalCacheService cacheService,
  })  : _apiClient = apiClient,
        _vault = vaultService,
        _cache = cacheService;

  bool get _isSignedIn => !_cache.isGuest && (_cache.getAuthToken()?.isNotEmpty ?? false);

  /// Local ids live in a high range so they never collide with server ids.
  static const int _localIdFloor = 1000000000;

  int _nextLocalId() {
    final base = _localIdFloor + DateTime.now().millisecondsSinceEpoch ~/ 1000 % _localIdFloor;
    final existing = _readLocal().map((c) => c.id);
    final maxExisting = existing.isEmpty ? 0 : existing.reduce((a, b) => a > b ? a : b);
    return base > maxExisting ? base : maxExisting + 1;
  }

  List<UserCardModel> _readLocal() {
    final raw = _cache.getWalletCards();
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => UserCardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeLocal(List<UserCard> cards) {
    return _cache.setWalletCards(
      jsonEncode(cards.map((c) => UserCardModel.fromEntity(c).toJson()).toList()),
    );
  }

  List<UserCard> _applyOrder(List<UserCard> cards) {
    final order = _cache.getWalletOrder();
    if (order.isEmpty) return cards;
    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    final sorted = [...cards]..sort((a, b) => (rank[a.id] ?? 1 << 20).compareTo(rank[b.id] ?? 1 << 20));
    return sorted;
  }

  Future<List<UserCard>> _withVaultFlags(List<UserCard> cards) async {
    final result = <UserCard>[];
    for (final c in cards) {
      result.add(c.copyWith(hasVaultDetails: await _vault.hasCardSecrets(c.id)));
    }
    return result;
  }

  /// Pushes cards created as a guest / offline to the server and re-keys
  /// their vault secrets to the new server ids. Cards that fail stay local.
  Future<List<UserCard>> _uploadLocalOnly(Iterable<UserCard> cards) async {
    final result = <UserCard>[];
    final order = _cache.getWalletOrder();
    for (final c in cards) {
      final remote = await _apiClient.post<UserCard>(
        path: ApiEndpoints.userCards,
        data: {
          'card_id': c.cardId,
          'nickname': c.nickname,
          'last_4_digits': c.last4Digits,
          'billing_cycle_day': c.billingCycleDay,
        },
        fromJson: (data) => UserCardModel.fromJson(data as Map<String, dynamic>),
      );
      if (remote case ApiSuccess(:final data)) {
        await _vault.moveCardSecrets(c.id, data.id);
        final i = order.indexOf(c.id);
        if (i != -1) order[i] = data.id;
        result.add(c.copyWith(id: data.id));
      } else {
        result.add(c);
      }
    }
    if (result.isNotEmpty) await _cache.setWalletOrder(order);
    return result;
  }

  @override
  Future<ApiResult<List<UserCard>>> getUserCards({bool forceRefresh = false}) async {
    final local = _readLocal();

    if (_isSignedIn) {
      final remote = await _apiClient.get<List<UserCard>>(
        path: ApiEndpoints.userCards,
        fromJson: (data) {
          final list = data is List ? data : (data?['items'] as List? ?? const []);
          return list.map((e) => UserCardModel.fromJson(e as Map<String, dynamic>)).toList();
        },
      );
      if (remote case ApiSuccess(:final data)) {
        // Server has no rate/fee fields on the summary: keep the richer local copy when present.
        final byId = {for (final c in local) c.id: c};
        final merged = data.map((c) => byId[c.id]?.copyWith(nickname: c.nickname, last4Digits: c.last4Digits, billingCycleDay: c.billingCycleDay) ?? c).toList();
        final remoteIds = data.map((c) => c.id).toSet();
        merged.addAll(await _uploadLocalOnly(local.where((c) => c.id >= _localIdFloor && !remoteIds.contains(c.id))));
        final withFlags = await _withVaultFlags(merged);
        await _writeLocal(withFlags);
        return ApiSuccess(_applyOrder(withFlags));
      }
      if (local.isEmpty && remote is ApiFailure<List<UserCard>> && !remote.isNetworkError) {
        return ApiFailure(remote.message, statusCode: remote.statusCode);
      }
    }

    return ApiSuccess(_applyOrder(await _withVaultFlags(local)));
  }

  @override
  Future<ApiResult<UserCard>> addUserCard({
    required CatalogCard card,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  }) async {
    var id = _nextLocalId();

    if (_isSignedIn) {
      // Only non-sensitive metadata is sent.
      final remote = await _apiClient.post<UserCard>(
        path: ApiEndpoints.userCards,
        data: {
          'card_id': card.id,
          'nickname': nickname,
          'last_4_digits': last4Digits,
          'billing_cycle_day': billingCycleDay,
        },
        fromJson: (data) => UserCardModel.fromJson(data as Map<String, dynamic>),
      );
      if (remote case ApiSuccess(:final data)) {
        id = data.id;
      } else if (remote is ApiFailure<UserCard> && !remote.isNetworkError) {
        return ApiFailure(remote.message, statusCode: remote.statusCode);
      }
    }

    final hasSecrets = fullCardNumber != null && fullCardNumber.replaceAll(RegExp(r'\D'), '').length >= 12;
    if (hasSecrets) {
      await _vault.saveCardSecrets(userCardId: id, cardNumber: fullCardNumber, cvv: cvv, expiry: expiry);
    }

    final created = UserCardModel.fromCatalog(
      id: id,
      card: card,
      nickname: nickname,
      last4Digits: last4Digits,
      billingCycleDay: billingCycleDay,
      hasVaultDetails: hasSecrets,
    );

    final local = _readLocal()..removeWhere((c) => c.id == id);
    await _writeLocal([...local, created]);
    return ApiSuccess(created);
  }

  @override
  Future<ApiResult<UserCard>> updateUserCard(UserCard card, {String? nickname, int? billingCycleDay}) async {
    if (_isSignedIn) {
      final remote = await _apiClient.patch<UserCard>(
        path: ApiEndpoints.userCardById(card.id),
        data: {
          'nickname': ?nickname,
          'billing_cycle_day': ?billingCycleDay,
        },
        fromJson: (data) => UserCardModel.fromJson(data as Map<String, dynamic>),
      );
      if (remote is ApiFailure<UserCard> && !remote.isNetworkError && remote.statusCode != 404) {
        return ApiFailure(remote.message, statusCode: remote.statusCode);
      }
    }

    final updated = card.copyWith(nickname: nickname, billingCycleDay: billingCycleDay);
    final local = _readLocal();
    final index = local.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      await _writeLocal([...local, updated]);
    } else {
      local[index] = UserCardModel.fromEntity(updated);
      await _writeLocal(local);
    }
    return ApiSuccess(updated);
  }

  @override
  Future<ApiResult<bool>> deleteUserCard(int userCardId) async {
    if (_isSignedIn) {
      final remote = await _apiClient.delete<bool>(
        path: ApiEndpoints.userCardById(userCardId),
        fromJson: (_) => true,
      );
      if (remote is ApiFailure<bool> && !remote.isNetworkError && remote.statusCode != 404) {
        return ApiFailure(remote.message, statusCode: remote.statusCode);
      }
    }
    await _vault.deleteCardSecrets(userCardId);
    await _writeLocal(_readLocal()..removeWhere((c) => c.id == userCardId));
    await _cache.setWalletOrder(_cache.getWalletOrder()..remove(userCardId));
    return const ApiSuccess(true);
  }

  @override
  Future<void> saveOrder(List<int> orderedIds) => _cache.setWalletOrder(orderedIds);

  @override
  Future<List<UserCard>> loadSampleCards() async {
    const samples = [
      (1, 'Travel', '9012', 15, '4532981234569012', '889', '12/29'),
      (2, 'Online shopping', '4321', 5, '5412753489014321', '412', '09/28'),
      (3, 'Flights & miles', '7765', 20, '4111222233337765', '123', '04/30'),
    ];
    final created = <UserCard>[];
    for (final (cardId, nickname, last4, day, pan, cvv, exp) in samples) {
      final card = MockSeedData.sampleCards.firstWhere((c) => c.id == cardId);
      final result = await addUserCard(
        card: card,
        nickname: nickname,
        last4Digits: last4,
        billingCycleDay: day,
        fullCardNumber: pan,
        cvv: cvv,
        expiry: exp,
      );
      if (result case ApiSuccess(:final data)) created.add(data);
    }
    return created;
  }

  @override
  Future<VaultStatus> copyCardNumber(int userCardId, {required Duration clearAfter}) {
    return _vault.copyCardNumber(userCardId, clearAfter: clearAfter, reason: AppStrings.biometricCopyReason);
  }

  @override
  Future<VaultStatus> copyField(int userCardId, String field, {required Duration clearAfter}) {
    return _vault.copyField(
      userCardId,
      field,
      clearAfter: clearAfter,
      reason: AppStrings.biometricRevealReason,
    );
  }

  @override
  Future<(VaultStatus, VaultSecrets?)> readSecrets(int userCardId) {
    return _vault.readSecrets(userCardId, reason: AppStrings.biometricRevealReason);
  }

  @override
  Future<void> clearLocalWallet() async {
    for (final c in _readLocal()) {
      await _vault.deleteCardSecrets(c.id);
    }
    await _cache.setWalletCards('[]');
    await _cache.setWalletOrder(const []);
  }
}
