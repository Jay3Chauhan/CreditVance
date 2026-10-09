import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/raw_sms.dart';

/// Raw runtime permission state reported by the native layer.
class NativeSmsPermission {
  final bool granted;

  /// Android's `shouldShowRequestPermissionRationale` — false after
  /// "Don't ask again" (or before the first request).
  final bool shouldShowRationale;

  const NativeSmsPermission({required this.granted, required this.shouldShowRationale});

  static const NativeSmsPermission unsupported = NativeSmsPermission(granted: false, shouldShowRationale: false);
}

/// Platform bridge for reading bank SMS. Android-only; other platforms report
/// unsupported and return no data.
abstract class SmsPlatformDataSource {
  bool get isSupported;

  Future<NativeSmsPermission> checkPermission();

  /// Shows the READ_SMS + RECEIVE_SMS system dialog.
  Future<NativeSmsPermission> requestPermission();

  Future<void> openAppSettings();

  /// Inbox SMS newer than [since] whose sender header contains one of
  /// [senderKeys], oldest first. Filtering happens natively so non-bank SMS
  /// bodies never reach Dart.
  Future<List<RawSms>> queryInbox({required DateTime since, required List<String> senderKeys, required int limit});

  /// Content-free notifications (receive timestamps) for new bank SMS while
  /// the app is running.
  Stream<DateTime> incomingBankSms(List<String> senderKeys);
}

/// [SmsPlatformDataSource] backed by the custom Kotlin MethodChannel/EventChannel
/// in `android/app/src/main/kotlin/.../SmsBridge.kt`.
class MethodChannelSmsDataSource implements SmsPlatformDataSource {
  static const MethodChannel _channel = MethodChannel('com.cardsage/sms');
  static const EventChannel _events = EventChannel('com.cardsage/sms_incoming');

  const MethodChannelSmsDataSource();

  @override
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  NativeSmsPermission _fromMap(Map<Object?, Object?>? map) => NativeSmsPermission(
        granted: map?['granted'] == true,
        shouldShowRationale: map?['shouldShowRationale'] == true,
      );

  @override
  Future<NativeSmsPermission> checkPermission() async {
    if (!isSupported) return NativeSmsPermission.unsupported;
    try {
      return _fromMap(await _channel.invokeMapMethod<Object?, Object?>('checkPermission'));
    } on PlatformException {
      return const NativeSmsPermission(granted: false, shouldShowRationale: true);
    } on MissingPluginException {
      return NativeSmsPermission.unsupported;
    }
  }

  @override
  Future<NativeSmsPermission> requestPermission() async {
    if (!isSupported) return NativeSmsPermission.unsupported;
    try {
      return _fromMap(await _channel.invokeMapMethod<Object?, Object?>('requestPermission'));
    } on PlatformException {
      return checkPermission();
    } on MissingPluginException {
      return NativeSmsPermission.unsupported;
    }
  }

  @override
  Future<void> openAppSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } on PlatformException {
      // Settings unavailable on this device; nothing else to do.
    } on MissingPluginException {
      // Not running on the Android host.
    }
  }

  @override
  Future<List<RawSms>> queryInbox({
    required DateTime since,
    required List<String> senderKeys,
    required int limit,
  }) async {
    if (!isSupported) return const [];
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>('queryInbox', {
      'sinceMillis': since.millisecondsSinceEpoch,
      'senderKeys': senderKeys,
      'limit': limit,
    });
    return [
      for (final row in rows ?? const <Map<Object?, Object?>>[])
        RawSms(
          sender: row['address'] as String? ?? '',
          body: row['body'] as String? ?? '',
          receivedAt: DateTime.fromMillisecondsSinceEpoch((row['date'] as num?)?.toInt() ?? 0),
        ),
    ];
  }

  @override
  Stream<DateTime> incomingBankSms(List<String> senderKeys) {
    if (!isSupported) return const Stream.empty();
    return _events.receiveBroadcastStream({'senderKeys': senderKeys}).map((event) {
      final millis = event is Map ? (event['date'] as num?)?.toInt() : null;
      return millis == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(millis);
    });
  }
}
