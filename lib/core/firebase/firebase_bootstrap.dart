import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';
import 'firebase_options.dart';
import 'messaging_service.dart';

/// Starts Firebase and the free products that ship with the mobile apps.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool ready = false;

  static Future<bool> start() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (error, stack) {
      debugPrint('Firebase init failed: $error\n$stack');
      return false;
    }

    ready = true;
    _installCrashHandlers();
    await AnalyticsService.applyCollection(true);
    await MessagingService.start();
    return true;
  }

  static void _installCrashHandlers() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutter?.call(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return previousPlatform?.call(error, stack) ?? true;
    };
  }
}
