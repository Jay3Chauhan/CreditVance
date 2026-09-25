import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/local_cache_service.dart';
import 'api_result.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'network_info.dart';

/// Production-grade Dio HTTP client with logging, token injection,
/// typed error conversion, and offline resilience.
class ApiClient {
  late final Dio _dio;
  final LocalCacheService _cacheService;
  final NetworkInfo _networkInfo;

  ApiClient({
    required LocalCacheService cacheService,
    NetworkInfo? networkInfo,
    Dio? dio,
  })  : _cacheService = cacheService,
        _networkInfo = networkInfo ?? NetworkInfo() {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: ApiEndpoints.connectTimeout,
            receiveTimeout: ApiEndpoints.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(AuthInterceptor(_cacheService));
    _dio.interceptors.add(const LoggingInterceptor());
  }

  Dio get dio => _dio;

  /// Performs GET request and parses response
  Future<ApiResult<T>> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiFailure('Unexpected error: $e', originalError: e);
    }
  }

  /// Performs POST request
  Future<ApiResult<T>> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiFailure('Unexpected error: $e', originalError: e);
    }
  }

  /// Performs PATCH request
  Future<ApiResult<T>> patch<T>({
    required String path,
    dynamic data,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiFailure('Unexpected error: $e', originalError: e);
    }
  }

  /// Performs DELETE request
  Future<ApiResult<T>> delete<T>({
    required String path,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiFailure('Unexpected error: $e', originalError: e);
    }
  }

  ApiResult<T> _handleResponse<T>(
    Response response,
    T Function(dynamic data) fromJson,
  ) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      // Backend follows: {"success": true, "message": "...", "data": ...}
      final isSuccess = body['success'] == true;
      if (isSuccess && body.containsKey('data')) {
        return ApiSuccess(fromJson(body['data']), message: body['message'] as String?);
      }
      if (!isSuccess) {
        return ApiFailure(
          body['message'] as String? ?? 'Operation failed',
          statusCode: response.statusCode,
        );
      }
    }
    return ApiSuccess(fromJson(body));
  }

  ApiResult<T> _handleDioError<T>(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const ApiFailure('Connection timeout or network unavailable. Showing cached data.');
    }

    final response = error.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final errorMap = response.data as Map<String, dynamic>;
      final message = errorMap['message'] ?? errorMap['detail'] ?? 'Server error';
      return ApiFailure(message.toString(), statusCode: response.statusCode, originalError: error);
    }

    return ApiFailure(
      error.message ?? 'Network connection failed.',
      statusCode: response?.statusCode,
      originalError: error,
    );
  }
}
