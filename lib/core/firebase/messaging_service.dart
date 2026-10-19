import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../navigation/root_navigator.dart';
import '../network/api_client.dart';
import '../network/api_result.dart';
import '../utils/app_toast.dart';
import 'analytics_service.dart';
import 'firebase_bootstrap.dart';
import 'firebase_options.dart';

enum PushPermission { granted, denied, unavailable }

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[FCM Background] Received message: ${message.messageId}, data: ${message.data}');
  } catch (error) {
    debugPrint('[FCM Background] Init failed: $error');
  }
}

class MessagingService {
  const MessagingService._();

  static String? _currentToken;
  static String? get currentToken => _currentToken;

  static ApiClient? _activeApiClient;

  /// Starts the Firebase Messaging listeners, fetches and logs the FCM token,
  /// and listens for incoming alerts and token refreshes.
  static Future<void> start({ApiClient? apiClient}) async {
    if (apiClient != null) {
      _activeApiClient = apiClient;
    }
    if (!FirebaseBootstrap.ready) {
      debugPrint('[FCM] Firebase not ready; skipping messaging start');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle messages received while app is in the foreground
      FirebaseMessaging.onMessage.listen(_showForeground);

      // Handle notification clicks when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // Check if the app was launched by tapping a notification from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _logToken(newToken, reason: 'TOKEN REFRESHED');
        if (_activeApiClient != null) {
          syncDeviceToken(_activeApiClient!, token: newToken);
        }
      });

      // Fetch and log the current device token
      await getToken();
    } catch (error, stack) {
      debugPrint('[FCM] Messaging start failed: $error\n$stack');
    }
  }

  /// Binds or updates the active API client for automatic token synchronization.
  static void bindApiClient(ApiClient apiClient) {
    _activeApiClient = apiClient;
  }

  /// Retrieves the current FCM token, caches it in memory, and logs it clearly.
  static Future<String?> getToken({bool forceLog = true}) async {
    if (!FirebaseBootstrap.ready) return null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _currentToken = token;
      if (token != null && forceLog) {
        _logToken(token, reason: 'INITIALIZED');
      }
      return token;
    } catch (error) {
      debugPrint('[FCM] Failed to get device token: $error');
      return null;
    }
  }

  static void _logToken(String token, {required String reason}) {
    debugPrint('═══════════════════════════════════════════════════════════════════════════');
    debugPrint('[FCM] DEVICE REGISTRATION TOKEN ($reason):');
    debugPrint(token);
    debugPrint('═══════════════════════════════════════════════════════════════════════════');
  }

  /// Registers or updates this device's FCM token with the Credvert backend API.
  static Future<bool> syncDeviceToken(ApiClient apiClient, {String? token}) async {
    _activeApiClient = apiClient;
    final deviceToken = token ?? _currentToken ?? await getToken();
    if (deviceToken == null || deviceToken.isEmpty) {
      debugPrint('[FCM] Cannot register device token: token is null or empty');
      return false;
    }

    final platformName = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : 'android';

    debugPrint('[FCM] Registering device token with backend: $deviceToken ($platformName)...');

    final result = await apiClient.post<dynamic>(
      path: ApiEndpoints.notificationDeviceToken,
      data: {
        'device_token': deviceToken,
        'platform': platformName,
      },
      fromJson: (data) => data,
    );

    return result.when(
      success: (data) {
        debugPrint('[FCM] Successfully registered device token with Credvert server.');
        return true;
      },
      failure: (message, code) {
        debugPrint('[FCM] Failed to register device token with server: $message (code: $code)');
        return false;
      },
    );
  }

  /// Unregisters this device's token on logout.
  static Future<bool> unregisterDeviceToken(ApiClient apiClient, {String? token}) async {
    final deviceToken = token ?? _currentToken;
    if (deviceToken == null || deviceToken.isEmpty) return true;

    debugPrint('[FCM] Unregistering device token from server...');

    final result = await apiClient.delete<dynamic>(
      path: ApiEndpoints.notificationDeviceToken,
      queryParameters: {'device_token': deviceToken},
      fromJson: (data) => data,
    );

    return result.when(
      success: (_) {
        debugPrint('[FCM] Successfully removed device token from server.');
        return true;
      },
      failure: (msg, code) {
        debugPrint('[FCM] Note: server token unregister returned: $msg ($code)');
        return false;
      },
    );
  }

  /// Sends a test notification to all registered devices for the current account.
  static Future<ApiResult<dynamic>> sendTestNotification(ApiClient apiClient) {
    debugPrint('[FCM] Requesting test notification from server...');
    return apiClient.post<dynamic>(
      path: ApiEndpoints.notificationTest,
      fromJson: (data) => data,
    );
  }

  static void _showForeground(RemoteMessage message) {
    debugPrint('[FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}, data: ${message.data}');
    final notification = message.notification;
    final body = notification?.body?.trim();
    final title = notification?.title?.trim();
    final text = (body != null && body.isNotEmpty) ? body : title;
    if (text == null || text.isEmpty) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    AppToast.info(context, title: title == text ? null : title, message: text);
  }

  static void _handleNotificationClick(RemoteMessage message) {
    debugPrint('[FCM Click] Notification tapped. Data: ${message.data}');
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      debugPrint('[FCM Routing] Deep link route: $route');
      // Navigation routing can be dispatched via rootNavigatorKey if desired
    }
  }

  static Future<PushPermission> requestPermission({ApiClient? apiClient}) async {
    if (!FirebaseBootstrap.ready) return PushPermission.unavailable;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings.authorizationStatus;
      final granted = status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
      await AnalyticsService.log('notification_permission', {'status': status.name});

      if (granted) {
        final token = await getToken();
        final client = apiClient ?? _activeApiClient;
        if (client != null && token != null) {
          await syncDeviceToken(client, token: token);
        }
        return PushPermission.granted;
      }
      return PushPermission.denied;
    } catch (error) {
      debugPrint('[FCM] Notification permission request failed: $error');
      return PushPermission.unavailable;
    }
  }
}
