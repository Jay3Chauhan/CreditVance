import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized API Endpoints and Network Configuration for CardSage.
class ApiEndpoints {
  const ApiEndpoints._();

  /// Resolves the optimal base URL depending on device platform
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://localhost:8000/api/v1';
  }

  // Network Timeout durations
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 8);

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Catalog
  static const String cards = '/cards';
  static String cardDetail(String slug) => '/cards/$slug';
  static String cardTab(String slug, String tabName) => '/cards/$slug/tabs/$tabName';

  // User Cards & Portfolio
  static const String userCards = '/user-cards';
  static String userCardById(int id) => '/user-cards/$id';

  // Advisor & Calculator
  static const String advisorRecommend = '/advisor/recommend';
  static const String calculator = '/calculator/calculate';

  // Taxonomies
  static const String banks = '/banks';
  static const String categories = '/categories';
}
