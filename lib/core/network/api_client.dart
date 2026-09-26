import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/local_cache_service.dart';
import 'api_result.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'network_info.dart';

/// Dio HTTP client with token injection, typed errors and envelope parsing.
///
/// Backend envelope: `{"success": bool, "message": str, "data": ..., "meta": {...}}`.
class ApiClient {
  late final Dio _dio;
  final NetworkInfo _networkInfo;
  late final AuthInterceptor _authInterceptor;

  NetworkInfo get networkInfo => _networkInfo;

  ApiClient({
    required LocalCacheService cacheService,
    NetworkInfo? networkInfo,
    Dio? dio,
  }) : _networkInfo = networkInfo ?? NetworkInfo() {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: ApiEndpoints.connectTimeout,
            receiveTimeout: ApiEndpoints.receiveTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
    _authInterceptor = AuthInterceptor(cacheService);
    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(const LoggingInterceptor());
  }

  set onUnauthorized(void Function()? callback) => _authInterceptor.onUnauthorized = callback;

  Future<ApiResult<T>> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) =>
      _send(() => _dio.get(path, queryParameters: queryParameters), fromJson);

  Future<ApiResult<T>> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) =>
      _send(() => _dio.post(path, data: data, queryParameters: queryParameters), fromJson);

  Future<ApiResult<T>> patch<T>({
    required String path,
    dynamic data,
    required T Function(dynamic data) fromJson,
  }) =>
      _send(() => _dio.patch(path, data: data), fromJson);

  Future<ApiResult<T>> delete<T>({
    required String path,
    required T Function(dynamic data) fromJson,
  }) =>
      _send(() => _dio.delete(path), fromJson);

  Future<ApiResult<T>> _send<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) fromJson,
  ) async {
    try {
      final response = await request();
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiFailure('Unexpected error: $e', originalError: e);
    }
  }

  ApiResult<T> _handleResponse<T>(Response<dynamic> response, T Function(dynamic data) fromJson) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('success')) {
      if (body['success'] == true) {
        return ApiSuccess(
          fromJson(body['data']),
          message: body['message'] as String?,
          meta: body['meta'] as Map<String, dynamic>?,
        );
      }
      return ApiFailure(
        body['message'] as String? ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    return ApiSuccess(fromJson(body));
  }

  ApiResult<T> _handleDioError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return ApiFailure(
          'You\'re offline or the server is unreachable.',
          originalError: error,
          isNetworkError: true,
        );
      default:
        break;
    }

    final response = error.response;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      Object? detailMessage = detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        detailMessage = first is Map ? first['msg'] : first;
      }
      final message = data['message'] ?? detailMessage ?? 'Server error';
      return ApiFailure(message.toString(), statusCode: response?.statusCode, originalError: error);
    }

    return ApiFailure(
      error.message ?? 'Network request failed.',
      statusCode: response?.statusCode,
      originalError: error,
    );
  }
}
