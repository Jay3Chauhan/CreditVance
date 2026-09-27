import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/firebase/analytics_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../data/remote_config_keys.dart';
import '../data/remote_config_parser.dart';
import '../data/remote_config_source.dart';
import '../domain/app_remote_config.dart';
import '../domain/app_version.dart';

class RemoteConfigController extends ChangeNotifier {
  RemoteConfigController({required this.cache, required this.source});

  final LocalCacheService cache;
  final RemoteConfigSource source;

  AppRemoteConfig config = RemoteConfigParser.parse(MapRemoteConfigReader(RemoteConfigDefaults.map)).config;
  AppVersion version = const AppVersion(major: 1, minor: 0, patch: 0, build: 1);
  bool ready = false;
  bool refreshing = false;
  String? lastError;

  StreamSubscription<void>? _updates;
  bool _refreshing = false;
  bool _queued = false;
  final Set<String> _logged = {};

  String get versionLabel {
    final build = version.build > 0 ? ' (${version.build})' : '';
    return 'v${version.label}$build';
  }

  DateTime get _now => DateTime.now().toUtc();

  bool get maintenanceActive => config.maintenanceActive(_now);
  bool get forceUpdate => config.forceUpdateRequired(version);
  bool get softUpdate => config.softUpdateAvailable(version) && cache.dismissedUpdateKey != config.softUpdateKey;
  bool get announcementLive => config.announcementActive(_now);
  bool get blockingAnnouncement => announcementLive && config.announcementBlocks;
  bool get bannerAnnouncement =>
      announcementLive && !config.announcementBlocks && cache.dismissedAnnouncementId != config.announcementId;
  bool get whatsNew =>
      config.whatsNewEnabled && config.whatsNewVersion != null && cache.seenWhatsNewVersion != config.whatsNewVersion;

  Future<void> start() async {
    await _loadVersion();
    _updates = source.updates.listen((_) => refresh());
    await refresh();
  }

  Future<void> refresh({bool userInitiated = false}) async {
    if (_refreshing) {
      _queued = true;
      return;
    }
    _refreshing = true;
    refreshing = true;
    notifyListeners();
    try {
      final result = await source.fetch(force: userInitiated);
      final parsed = RemoteConfigParser.parse(result.reader);
      config = parsed.config;
      lastError = userInitiated ? result.warning : null;
      if (parsed.warnings.isNotEmpty) {
        final note = parsed.warnings.join(' | ');
        debugPrint('Remote Config: $note');
        AnalyticsService.breadcrumb(note);
        await AnalyticsService.log('remote_config_warning', {'count': parsed.warnings.length});
      }
      await AnalyticsService.log('remote_config_fetch', {'result': result.warning == null ? 'success' : 'fallback'});
      await AnalyticsService.setConfigKeys(version: versionLabel, maintenance: maintenanceActive, forceUpdate: forceUpdate);
    } catch (error, stack) {
      lastError = 'Could not refresh app settings.';
      debugPrint('Remote Config refresh failed: $error\n$stack');
      await AnalyticsService.record(error, stack, reason: 'remote_config_refresh');
    } finally {
      _refreshing = false;
      refreshing = false;
      ready = true;
      notifyListeners();
      if (_queued) {
        _queued = false;
        await refresh();
      }
    }
  }

  Future<void> dismissAnnouncement() async {
    final id = config.announcementId;
    if (id == null) return;
    await cache.setDismissedAnnouncement(id);
    await AnalyticsService.log('announcement_dismissed', {'id': id});
    notifyListeners();
  }

  Future<void> dismissSoftUpdate() async {
    await cache.setDismissedUpdate(config.softUpdateKey);
    await AnalyticsService.log('soft_update_dismissed', {'version': config.softUpdateKey});
    notifyListeners();
  }

  Future<void> dismissWhatsNew() async {
    final seen = config.whatsNewVersion;
    if (seen == null) return;
    await cache.setSeenWhatsNew(seen);
    notifyListeners();
  }

  void logOnce(String key, String event, [Map<String, Object>? parameters]) {
    if (!_logged.add(key)) return;
    AnalyticsService.log(event, parameters);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = AppVersion.fromPackage(version: info.version, buildNumber: info.buildNumber);
    } catch (error) {
      debugPrint('Package info failed: $error');
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }
}
