import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../navigation/root_navigator.dart';
import '../utils/app_toast.dart';
import 'analytics_service.dart';
import 'firebase_bootstrap.dart';
import 'firebase_options.dart';

enum PushPermission { granted, denied, unavailable }

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    debugPrint('Background message init failed: $error');
  }
}

class MessagingService {
  const MessagingService._();

  static Future<void> start() async {
    if (!FirebaseBootstrap.ready) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_showForeground);
    } catch (error, stack) {
      debugPrint('Messaging start failed: $error\n$stack');
    }
  }

  static void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    final body = notification?.body?.trim();
    final title = notification?.title?.trim();
    final text = (body != null && body.isNotEmpty) ? body : title;
    if (text == null || text.isEmpty) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    AppToast.info(context, title: title == text ? null : title, message: text);
  }

  static Future<PushPermission> requestPermission() async {
    if (!FirebaseBootstrap.ready) return PushPermission.unavailable;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      final status = settings.authorizationStatus;
      final granted = status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
      await AnalyticsService.log('notification_permission', {'status': status.name});
      return granted ? PushPermission.granted : PushPermission.denied;
    } catch (error) {
      debugPrint('Notification permission failed: $error');
      return PushPermission.unavailable;
    }
  }
}
