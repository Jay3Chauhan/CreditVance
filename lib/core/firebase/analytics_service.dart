import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// Thin wrappers so the rest of the app does not call Firebase directly.
class AnalyticsService {
  const AnalyticsService._();

  static Future<void> applyCollection(bool enabled) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
      final crashes = enabled && !kDebugMode;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(crashes);
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(crashes);
    } catch (error) {
      debugPrint('Diagnostics setting failed: $error');
    }
  }

  static Future<void> log(String name, [Map<String, Object>? parameters]) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics event failed: $error');
    }
  }

  static Future<void> screen(String name) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: name);
    } catch (error) {
      debugPrint('Screen view failed: $error');
    }
  }

  static Future<void> setAuth({String? userId, required String state}) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: userId);
      await FirebaseAnalytics.instance.setUserProperty(name: 'auth_state', value: state);
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (error) {
      debugPrint('Auth analytics failed: $error');
    }
  }

  static Future<void> setConfigKeys({
    required String version,
    required bool maintenance,
    required bool forceUpdate,
  }) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCustomKey('app_version', version);
      await crashlytics.setCustomKey('maintenance', maintenance);
      await crashlytics.setCustomKey('force_update', forceUpdate);
    } catch (error) {
      debugPrint('Crashlytics keys failed: $error');
    }
  }

  static Future<void> record(Object error, StackTrace stack, {required String reason}) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    } catch (_) {}
  }

  static void breadcrumb(String message) {
    if (!FirebaseBootstrap.ready) return;
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }
}
