import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Options taken from the existing Android and iOS Firebase config files.
///
/// Project: credvance-cb042
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is configured for the Android and iOS apps.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABE-2c40gsDffNvrnPTOUi2NteCzhJNco',
    appId: '1:755910372710:android:8ae40378b74ddd7b6deca7',
    messagingSenderId: '755910372710',
    projectId: 'credvance-cb042',
    storageBucket: 'credvance-cb042.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXapzu77P76Nqy4R2jaOIO5ogCoTS1WcM',
    appId: '1:755910372710:ios:28036474ddfaf3736deca7',
    messagingSenderId: '755910372710',
    projectId: 'credvance-cb042',
    storageBucket: 'credvance-cb042.firebasestorage.app',
    iosBundleId: 'com.jaychauhan.credvert',
  );
}
