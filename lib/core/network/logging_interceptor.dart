import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// MNC-Grade HTTP Logging Interceptor for Dio.
/// Formats and logs all outgoing requests, headers, payload, responses, and errors.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  void _log(String line) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(line);
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final method = options.method.toUpperCase();
      final uri = options.uri.toString();
      _log('┌─── [CARDSAGE HTTP REQUEST] ──────────────────────────────────────────');
      _log('│ 🚀 $method $uri');
      _log('│ ⏱️ Timeout: ${options.connectTimeout?.inSeconds ?? 0}s');
      
      if (options.headers.isNotEmpty) {
        final headersCopy = Map<String, dynamic>.from(options.headers);
        // Mask bearer token partially for security logs
        if (headersCopy.containsKey('Authorization')) {
          final authStr = headersCopy['Authorization'].toString();
          if (authStr.length > 20) {
            headersCopy['Authorization'] = '${authStr.substring(0, 15)}...[SECURED]';
          }
        }
        _log('│ 🔑 Headers: $headersCopy');
      }

      if (options.queryParameters.isNotEmpty) {
        _log('│ 🔍 Query: ${options.queryParameters}');
      }

      if (options.data != null) {
        _log('│ 📦 Body: ${_formatJson(options.data)}');
      }
      _log('└──────────────────────────────────────────────────────────────────────');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final code = response.statusCode;
      final uri = response.requestOptions.uri.toString();
      final icon = (code != null && code >= 200 && code < 300) ? '✅' : '⚠️';

      _log('┌─── [CARDSAGE HTTP RESPONSE: $code] ──────────────────────────────────');
      _log('│ $icon $uri');
      _log('│ 📦 Data: ${_formatJson(response.data)}');
      _log('└──────────────────────────────────────────────────────────────────────');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final code = err.response?.statusCode ?? 'NO_RESPONSE';
      final uri = err.requestOptions.uri.toString();

      _log('┌─── [CARDSAGE HTTP ERROR: $code] ─────────────────────────────────────');
      _log('│ ❌ $uri');
      _log('│ ⚠️ Message: ${err.message}');
      if (err.response?.data != null) {
        _log('│ 💥 Error Body: ${_formatJson(err.response?.data)}');
      }
      _log('└──────────────────────────────────────────────────────────────────────');
    }
    return handler.next(err);
  }

  String _formatJson(dynamic data) {
    if (data == null) return 'null';
    if (data is Map || data is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        final formatted = encoder.convert(data);
        if (formatted.length > 800) {
          return '${formatted.substring(0, 800)}...\n  [Truncated for console readability]';
        }
        return formatted;
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
  }
}
