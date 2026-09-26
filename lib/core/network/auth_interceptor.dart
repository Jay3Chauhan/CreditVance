import 'package:dio/dio.dart';
import '../storage/local_cache_service.dart';

/// Attaches the JWT and reports expired sessions.
///
/// Guest sessions never send a token, so the backend is only asked for
/// user-scoped data when the user actually signed in.
class AuthInterceptor extends Interceptor {
  final LocalCacheService _cacheService;

  /// Invoked once when an authenticated request returns 401.
  void Function()? onUnauthorized;

  AuthInterceptor(this._cacheService, {this.onUnauthorized});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _cacheService.getAuthToken();
    if (!_cacheService.isGuest && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && hadToken) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
