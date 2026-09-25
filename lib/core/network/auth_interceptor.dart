import 'package:dio/dio.dart';
import '../storage/local_cache_service.dart';

/// Interceptor that attaches JWT Bearer token and intercepts 401s
class AuthInterceptor extends Interceptor {
  final LocalCacheService _cacheService;
  final void Function()? onUnauthorized;

  AuthInterceptor(this._cacheService, {this.onUnauthorized});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _cacheService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _cacheService.clearAuthToken();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
