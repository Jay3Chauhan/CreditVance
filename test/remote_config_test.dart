import 'package:credvert/features/remote_config/data/remote_config_keys.dart';
import 'package:credvert/features/remote_config/data/remote_config_parser.dart';
import 'package:credvert/features/remote_config/domain/app_remote_config.dart';
import 'package:credvert/features/remote_config/domain/app_version.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final installed = const AppVersion(major: 1, minor: 2, patch: 0, build: 12);
  final now = DateTime.utc(2026, 9, 27, 6, 0);

  AppRemoteConfig parse(Map<String, Object?> overrides) {
    return RemoteConfigParser.parse(MapRemoteConfigReader({...RemoteConfigDefaults.map, ...overrides})).config;
  }

  List<String> warnings(Map<String, Object?> overrides) {
    return RemoteConfigParser.parse(MapRemoteConfigReader({...RemoteConfigDefaults.map, ...overrides})).warnings;
  }

  group('AppVersion', () {
    test('parses major.minor.patch and ignores anything else', () {
      expect(AppVersion.tryParse('2.10.3')?.label, '2.10.3');
      expect(AppVersion.tryParse('1.0'), isNull);
      expect(AppVersion.tryParse('1.0.0-beta'), isNull);
      expect(AppVersion.tryParse('v1.0.0'), isNull);
    });

    test('reads the installed package version and build', () {
      final version = AppVersion.fromPackage(version: '1.4.2', buildNumber: '48');
      expect(version.label, '1.4.2');
      expect(version.build, 48);
    });

    test('orders by major, then minor, then patch', () {
      const older = AppVersion(major: 1, minor: 9, patch: 9);
      const newer = AppVersion(major: 2, minor: 0, patch: 0);
      expect(older.compareTo(newer), lessThan(0));
    });
  });

  group('version policy', () {
    test('does not force or suggest an update on the defaults', () {
      final config = parse(const {});
      expect(config.forceUpdateRequired(installed), isFalse);
      expect(config.softUpdateAvailable(installed), isFalse);
    });

    test('forces an update when the installed version is below the minimum', () {
      final config = parse({
        RemoteConfigKeys.forceUpdateEnabled: true,
        RemoteConfigKeys.minSupportedVersion: '1.3.0',
      });
      expect(config.forceUpdateRequired(installed), isTrue);
      expect(config.softUpdateAvailable(installed), isFalse);
    });

    test('does not force an update when the installed version matches the minimum', () {
      final config = parse({
        RemoteConfigKeys.forceUpdateEnabled: true,
        RemoteConfigKeys.minSupportedVersion: '1.2.0',
      });
      expect(config.forceUpdateRequired(installed), isFalse);
    });

    test('forces an update from the build floor even on the same version name', () {
      final config = parse({
        RemoteConfigKeys.forceUpdateEnabled: true,
        RemoteConfigKeys.minSupportedVersion: '1.2.0',
        RemoteConfigKeys.minSupportedBuild: 20,
      });
      expect(config.forceUpdateRequired(installed), isTrue);
    });

    test('ignores a broken minimum version instead of locking everyone out', () {
      final config = parse({
        RemoteConfigKeys.forceUpdateEnabled: true,
        RemoteConfigKeys.minSupportedVersion: 'latest',
      });
      expect(config.forceUpdateRequired(installed), isFalse);
      expect(warnings({RemoteConfigKeys.minSupportedVersion: 'latest'}), isNotEmpty);
    });

    test('suggests a soft update only when it is enabled and this build is older', () {
      final config = parse({
        RemoteConfigKeys.softUpdateEnabled: true,
        RemoteConfigKeys.latestVersion: '1.4.0',
      });
      expect(config.softUpdateAvailable(installed), isTrue);
      expect(config.softUpdateKey, '1.4.0+0');
    });
  });

  group('maintenance and announcements', () {
    test('maintenance is immediate when no window is set', () {
      final config = parse({RemoteConfigKeys.maintenanceEnabled: true});
      expect(config.maintenanceActive(now), isTrue);
    });

    test('a future start or a past end keeps the app open', () {
      final upcoming = parse({
        RemoteConfigKeys.maintenanceEnabled: true,
        RemoteConfigKeys.maintenanceStartsAt: '2026-10-01T00:00:00Z',
      });
      final finished = parse({
        RemoteConfigKeys.maintenanceEnabled: true,
        RemoteConfigKeys.maintenanceEndsAt: '2026-09-01T00:00:00Z',
      });
      expect(upcoming.maintenanceActive(now), isFalse);
      expect(finished.maintenanceActive(now), isFalse);
    });

    test('an end before the start closes the window', () {
      final config = parse({
        RemoteConfigKeys.maintenanceEnabled: true,
        RemoteConfigKeys.maintenanceStartsAt: '2026-10-02T00:00:00Z',
        RemoteConfigKeys.maintenanceEndsAt: '2026-10-01T00:00:00Z',
      });
      expect(config.maintenanceActive(now), isFalse);
    });

    test('a critical announcement that cannot be dismissed blocks the app', () {
      final config = parse({
        RemoteConfigKeys.announcementEnabled: true,
        RemoteConfigKeys.announcementId: 'outage-1',
        RemoteConfigKeys.announcementTitle: 'Service notice',
        RemoteConfigKeys.announcementMessage: 'Payments are delayed.',
        RemoteConfigKeys.announcementSeverity: 'critical',
        RemoteConfigKeys.announcementDismissible: false,
      });
      expect(config.announcementActive(now), isTrue);
      expect(config.announcementBlocks, isTrue);
    });

    test('an announcement without an id is ignored', () {
      final config = parse({
        RemoteConfigKeys.announcementEnabled: true,
        RemoteConfigKeys.announcementTitle: 'Hello',
        RemoteConfigKeys.announcementMessage: 'World',
      });
      expect(config.announcementEnabled, isFalse);
    });

    test('rejects unsafe links and keeps a valid store link', () {
      final config = parse({
        RemoteConfigKeys.androidStoreUrl: 'javascript:alert(1)',
        RemoteConfigKeys.iosStoreUrl: 'https://apps.apple.com/app/id123',
        RemoteConfigKeys.supportEmail: 'not-an-email',
      });
      expect(config.androidStoreUrl, isNull);
      expect(config.iosStoreUrl, 'https://apps.apple.com/app/id123');
      expect(config.supportEmail, isNull);
      expect(config.storeUrlFor(TargetPlatform.iOS), 'https://apps.apple.com/app/id123');
      expect(config.storeUrlFor(TargetPlatform.android), isNull);
    });

    test('what\'s new needs a version and at most eight lines', () {
      final body = List.generate(10, (i) => 'Item $i').join('\n');
      final parsed = RemoteConfigParser.parse(
        MapRemoteConfigReader({
          ...RemoteConfigDefaults.map,
          RemoteConfigKeys.whatsNewEnabled: true,
          RemoteConfigKeys.whatsNewVersion: '1.4',
          RemoteConfigKeys.whatsNewBody: body,
        }),
      );
      expect(parsed.config.whatsNewEnabled, isTrue);
      expect(parsed.config.whatsNewItems, hasLength(8));
    });

    test('empty what\'s new copy is turned off', () {
      final config = parse({
        RemoteConfigKeys.whatsNewEnabled: true,
        RemoteConfigKeys.whatsNewVersion: '1.4.0',
      });
      expect(config.whatsNewEnabled, isFalse);
    });
  });
}
