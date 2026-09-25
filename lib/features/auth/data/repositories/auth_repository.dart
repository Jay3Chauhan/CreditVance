import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<ApiResult<User>> login(String email, String password);
  Future<ApiResult<User>> register(String email, String password, String fullName);
  Future<ApiResult<User>> loginAsDemo();
  Future<ApiResult<User>> getMe();
  Future<void> logout();
  bool get isAuthenticated;
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final LocalCacheService _cacheService;
  final SecureVaultService _vaultService;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required LocalCacheService cacheService,
    required SecureVaultService vaultService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService,
        _vaultService = vaultService;

  @override
  bool get isAuthenticated => _cacheService.getAuthToken() != null;

  @override
  Future<ApiResult<User>> login(String email, String password) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      path: ApiEndpoints.login,
      data: {'email': email.trim(), 'password': password.trim()},
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (result.isSuccess) {
      final token = result.dataOrNull?['access_token'] as String?;
      if (token != null) {
        await _cacheService.setAuthToken(token);
      }
      return getMe();
    }

    return ApiFailure(result.errorOrNull ?? 'Invalid email or password');
  }

  @override
  Future<ApiResult<User>> register(String email, String password, String fullName) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      path: ApiEndpoints.register,
      data: {
        'email': email.trim(),
        'password': password.trim(),
        'full_name': fullName.trim(),
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (result.isSuccess) {
      return login(email, password);
    }

    return ApiFailure(result.errorOrNull ?? 'Registration failed');
  }

  @override
  Future<ApiResult<User>> loginAsDemo() async {
    // 1. Try real login against live backend
    final real = await login('jay@cardsage.app', 'Password123!');
    if (real.isSuccess) return real;

    // 2. Offline demo fallback
    await _cacheService.setAuthToken('mock_demo_jwt_token_12345');
    const demoUser = UserModel(
      id: 1,
      email: 'jay@cardsage.app',
      fullName: 'Jay (Vault Owner)',
      isBiometricEnabled: true,
    );
    await _cacheService.setUserProfile(jsonEncode(demoUser.toJson()));
    return const ApiSuccess(demoUser);
  }

  @override
  Future<ApiResult<User>> getMe() async {
    final result = await _apiClient.get<User>(
      path: ApiEndpoints.me,
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );

    if (result.isSuccess) {
      final user = result.dataOrNull!;
      await _cacheService.setUserProfile(jsonEncode((user as UserModel).toJson()));
      return result;
    }

    // Offline fallback if token exists
    final cached = _cacheService.getUserProfile();
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return ApiSuccess(UserModel.fromJson(map));
      } catch (_) {}
    }

    return const ApiFailure('Unable to load user profile');
  }

  @override
  Future<void> logout() async {
    await _cacheService.clearAuthToken();
    await _cacheService.setUserProfile('');
    await _vaultService.clearAll();
  }
}
