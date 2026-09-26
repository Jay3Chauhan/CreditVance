import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<ApiResult<User>> login(String email, String password);
  Future<ApiResult<User>> register(String email, String password, String fullName);
  Future<User> continueAsGuest();

  /// Leaves guest mode for the sign-in screen, keeping the local wallet so
  /// it can be synced after signing in.
  Future<void> exitGuest();

  /// Restores the session from disk. Returns null when signed out.
  User? restoreSession();

  /// Refreshes the profile from `/auth/me` (signed-in only).
  Future<ApiResult<User>> refreshProfile();

  Future<void> logout();
}

/// Backend JWT auth plus an offline guest mode. Card secrets are never part
/// of any auth payload.
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final LocalCacheService _cache;

  AuthRepositoryImpl({required ApiClient apiClient, required LocalCacheService cacheService})
      : _apiClient = apiClient,
        _cache = cacheService;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(email.trim())) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String password, {bool isSignUp = false}) {
    if (password.isEmpty) return 'Enter your password';
    if (isSignUp && password.length < 8) return 'Use at least 8 characters';
    return null;
  }

  @override
  Future<ApiResult<User>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final result = await _apiClient.post<String>(
      path: ApiEndpoints.login,
      data: {'email': cleanEmail, 'password': password},
      fromJson: (data) => (data as Map<String, dynamic>)['access_token'] as String,
    );

    switch (result) {
      case ApiFailure(:final message, :final statusCode, :final isNetworkError):
        return ApiFailure(
          statusCode == 401 ? 'Incorrect email or password' : message,
          statusCode: statusCode,
          isNetworkError: isNetworkError,
        );
      case ApiSuccess(:final data):
        await _cache.setGuest(false);
        await _cache.setAuthToken(data);
        final me = await refreshProfile();
        if (me.isSuccess) return me;
        final fallback = User(id: 0, email: cleanEmail, fullName: '');
        return ApiSuccess(fallback);
    }
  }

  @override
  Future<ApiResult<User>> register(String email, String password, String fullName) async {
    final result = await _apiClient.post<User>(
      path: ApiEndpoints.register,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'full_name': fullName.trim(),
      },
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    if (result case ApiFailure(:final message, :final statusCode, :final isNetworkError)) {
      return ApiFailure(
        statusCode == 409 || message.toLowerCase().contains('exist')
            ? 'An account with this email already exists'
            : message,
        statusCode: statusCode,
        isNetworkError: isNetworkError,
      );
    }
    return login(email, password);
  }

  @override
  Future<User> continueAsGuest() async {
    await _cache.clearAuthToken();
    await _cache.clearUserProfile();
    await _cache.setGuest(true);
    return User.guest;
  }

  @override
  Future<void> exitGuest() => _cache.setGuest(false);

  @override
  User? restoreSession() {
    if (_cache.isGuest) return User.guest;
    final token = _cache.getAuthToken();
    if (token == null || token.isEmpty) return null;
    final raw = _cache.getUserProfile();
    if (raw != null && raw.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return const User(id: 0, email: '', fullName: '');
  }

  @override
  Future<ApiResult<User>> refreshProfile() async {
    final result = await _apiClient.get<UserModel>(
      path: ApiEndpoints.me,
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    if (result case ApiSuccess(:final data)) {
      await _cache.setUserProfile(jsonEncode(data.toJson()));
      return ApiSuccess(data);
    }
    final f = result as ApiFailure<UserModel>;
    return ApiFailure(f.message, statusCode: f.statusCode, isNetworkError: f.isNetworkError);
  }

  @override
  Future<void> logout() => _cache.clearSession();
}
