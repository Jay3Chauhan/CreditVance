import 'dart:convert';
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

/// Zero-Knowledge On-Device Auth Repository.
/// All user profile and authentication state is maintained locally without remote API dependency.
class AuthRepositoryImpl implements AuthRepository {
  final LocalCacheService _cacheService;
  final SecureVaultService _vaultService;

  AuthRepositoryImpl({
    ApiClient? apiClient, // Optional for backward compatibility, not used for remote calls
    required LocalCacheService cacheService,
    required SecureVaultService vaultService,
  })  : _cacheService = cacheService,
        _vaultService = vaultService;

  @override
  bool get isAuthenticated => _cacheService.getAuthToken() != null;

  @override
  Future<ApiResult<User>> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return const ApiFailure('Email and password cannot be empty');
    }

    if (cleanPass.length < 4) {
      return const ApiFailure('Password must be at least 4 characters');
    }

    final token = 'vault_local_session_${cleanEmail.hashCode}';
    await _cacheService.setAuthToken(token);

    // Look for existing cached profile or create new on-device profile
    final cached = _cacheService.getUserProfile();
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        final existingUser = UserModel.fromJson(map);
        if (existingUser.email.toLowerCase() == cleanEmail.toLowerCase()) {
          return ApiSuccess(existingUser);
        }
      } catch (_) {}
    }

    final nameFromEmail = cleanEmail.contains('@')
        ? cleanEmail.split('@').first
        : 'User';
    final capitalized = nameFromEmail.isNotEmpty
        ? nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1)
        : 'User';

    final user = UserModel(
      id: cleanEmail.hashCode.abs() % 10000 + 1,
      email: cleanEmail,
      fullName: capitalized,
      isBiometricEnabled: true,
    );

    await _cacheService.setUserProfile(jsonEncode(user.toJson()));
    return ApiSuccess(user);
  }

  @override
  Future<ApiResult<User>> register(String email, String password, String fullName) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();
    final cleanName = fullName.trim().isEmpty ? 'User' : fullName.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return const ApiFailure('Email and password cannot be empty');
    }

    final token = 'vault_local_session_${cleanEmail.hashCode}';
    await _cacheService.setAuthToken(token);

    final user = UserModel(
      id: cleanEmail.hashCode.abs() % 10000 + 1,
      email: cleanEmail,
      fullName: cleanName,
      isBiometricEnabled: true,
    );

    await _cacheService.setUserProfile(jsonEncode(user.toJson()));
    return ApiSuccess(user);
  }

  @override
  Future<ApiResult<User>> loginAsDemo() async {
    await _cacheService.setAuthToken('vault_local_demo_jwt_token_12345');
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
    final cached = _cacheService.getUserProfile();
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return ApiSuccess(UserModel.fromJson(map));
      } catch (_) {}
    }

    // Default to demo account if authenticated but profile missing
    if (isAuthenticated) {
      return loginAsDemo();
    }

    return const ApiFailure('No active vault session found');
  }

  @override
  Future<void> logout() async {
    await _cacheService.clearAuthToken();
    await _cacheService.setUserProfile('');
    await _vaultService.clearAll();
  }
}
