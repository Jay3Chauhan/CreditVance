import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'remote_config_keys.dart';
import 'remote_config_parser.dart';

class RemoteConfigFetch {
  final RemoteConfigReader reader;
  final String? warning;

  const RemoteConfigFetch({required this.reader, this.warning});
}

abstract class RemoteConfigSource {
  Future<RemoteConfigFetch> fetch({bool force = false});
  Stream<void> get updates;
}

class StaticRemoteConfigSource implements RemoteConfigSource {
  @override
  Future<RemoteConfigFetch> fetch({bool force = false}) async {
    return RemoteConfigFetch(reader: MapRemoteConfigReader(RemoteConfigDefaults.map));
  }

  @override
  Stream<void> get updates => const Stream.empty();
}

class FirebaseRemoteConfigSource implements RemoteConfigSource {
  FirebaseRemoteConfigSource(this._remote, this._updates);

  final FirebaseRemoteConfig _remote;
  final StreamController<void> _updates;

  static Future<FirebaseRemoteConfigSource> create() async {
    final remote = FirebaseRemoteConfig.instance;
    await remote.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ),
    );
    await remote.setDefaults(RemoteConfigDefaults.map);
    final updates = StreamController<void>.broadcast();
    remote.onConfigUpdated.listen(
      (_) async {
        try {
          await remote.activate();
          if (!updates.isClosed) updates.add(null);
        } catch (error, stack) {
          debugPrint('Remote Config activate failed: $error\n$stack');
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Remote Config listener failed: $error\n$stack');
      },
    );
    return FirebaseRemoteConfigSource(remote, updates);
  }

  @override
  Stream<void> get updates => _updates.stream;

  @override
  Future<RemoteConfigFetch> fetch({bool force = false}) async {
    final trace = FirebasePerformance.instance.newTrace('remote_config_fetch');
    try {
      await trace.start();
    } catch (_) {}

    try {
      if (force && !kDebugMode) {
        await _remote.setConfigSettings(
          RemoteConfigSettings(fetchTimeout: const Duration(seconds: 8), minimumFetchInterval: Duration.zero),
        );
      }
      await _remote.fetchAndActivate();
      return RemoteConfigFetch(reader: _FirebaseReader(_remote));
    } catch (error) {
      debugPrint('Remote Config fetch failed: $error');
      try {
        await _remote.activate();
      } catch (_) {}
      return RemoteConfigFetch(
        reader: _FirebaseReader(_remote),
        warning: 'Could not refresh app settings. Using the last saved values.',
      );
    } finally {
      if (force && !kDebugMode) {
        try {
          await _remote.setConfigSettings(
            RemoteConfigSettings(fetchTimeout: const Duration(seconds: 8), minimumFetchInterval: const Duration(hours: 1)),
          );
        } catch (_) {}
      }
      try {
        await trace.stop();
      } catch (_) {}
    }
  }
}

class _FirebaseReader implements RemoteConfigReader {
  final FirebaseRemoteConfig remote;
  _FirebaseReader(this.remote);

  @override
  String stringOf(String key) => remote.getString(key);

  @override
  bool boolOf(String key) => remote.getBool(key);

  @override
  int intOf(String key) => remote.getInt(key);
}
