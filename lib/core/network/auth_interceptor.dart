import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/local_cache_service.dart';

/// Attaches the JWT, refreshes it once on 401, and reports a dead session.
///
/// Guest sessions never send a token. The refresh call uses a bare Dio so it
/// cannot recurse through this interceptor.
class AuthInterceptor extends Interceptor {
  final LocalCacheService _cache;
  final Dio _refreshDio;

  Dio? _dio;
  Future<bool>? _refreshing;

  /// Invoked when a refresh fails and the signed-in session must end.
  void Function()? onUnauthorized;

  AuthInterceptor(this._cache)
      : _refreshDio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: ApiEndpoints.connectTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        ));

  void bind(Dio dio) => _dio = dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _cache.getAuthToken();
    if (!_cache.isGuest && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    final canRefresh = err.response?.statusCode == 401 &&
        hadToken &&
        err.requestOptions.extra['retried'] != true &&
        _dio != null &&
        _cache.getRefreshToken() != null;

    if (!canRefresh) {
      if (err.response?.statusCode == 401 && hadToken) onUnauthorized?.call();
      handler.next(err);
      return;
    }

    final ok = await (_refreshing ??= _refresh());
    _refreshing = null;
    if (!ok) {
      onUnauthorized?.call();
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    options.extra['retried'] = true;
    options.headers['Authorization'] = 'Bearer ${_cache.getAuthToken()}';
    try {
      final response = await _dio!.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _refresh() async {
    final refresh = _cache.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await _refreshDio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refresh},
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] ?? body : null;
      if (data is! Map) return false;
      final access = data['access_token'] as String?;
      final nextRefresh = data['refresh_token'] as String?;
      if (access == null || access.isEmpty) return false;
      await _cache.setAuthToken(access);
      if (nextRefresh != null && nextRefresh.isNotEmpty) await _cache.setRefreshToken(nextRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }
}
