import '../domain/app_remote_config.dart';
import '../domain/app_version.dart';
import 'remote_config_keys.dart';

abstract class RemoteConfigReader {
  String stringOf(String key);
  bool boolOf(String key);
  int intOf(String key);
}

class MapRemoteConfigReader implements RemoteConfigReader {
  final Map<String, Object?> values;

  MapRemoteConfigReader(this.values);

  @override
  String stringOf(String key) => values[key]?.toString() ?? '';

  @override
  bool boolOf(String key) {
    final value = values[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.trim().toLowerCase() == 'true';
    return false;
  }

  @override
  int intOf(String key) {
    final value = values[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class ParsedRemoteConfig {
  final AppRemoteConfig config;
  final List<String> warnings;

  const ParsedRemoteConfig(this.config, this.warnings);
}

class RemoteConfigParser {
  const RemoteConfigParser._();

  static ParsedRemoteConfig parse(RemoteConfigReader reader) {
    final warnings = <String>[];

    var schema = reader.intOf(RemoteConfigKeys.schemaVersion);
    if (schema < 1) {
      warnings.add('config_schema_version was missing or invalid; using 1');
      schema = 1;
    } else if (schema > 1) {
      warnings.add('config_schema_version $schema is newer than this app; known settings still apply');
    }

    final maintenanceStarts = _date(reader, RemoteConfigKeys.maintenanceStartsAt, warnings);
    final maintenanceEnds = _date(reader, RemoteConfigKeys.maintenanceEndsAt, warnings);
    _warnWindow(maintenanceStarts, maintenanceEnds, 'maintenance', warnings);

    final announcementStarts = _date(reader, RemoteConfigKeys.announcementStartsAt, warnings);
    final announcementEnds = _date(reader, RemoteConfigKeys.announcementEndsAt, warnings);
    _warnWindow(announcementStarts, announcementEnds, 'announcement', warnings);

    final announcementId = _token(
      reader.stringOf(RemoteConfigKeys.announcementId),
      warnings,
      RemoteConfigKeys.announcementId,
      max: 64,
    );
    final announcementTitle = _optional(reader.stringOf(RemoteConfigKeys.announcementTitle), 80, warnings, RemoteConfigKeys.announcementTitle, title: true);
    final announcementMessage = _optional(reader.stringOf(RemoteConfigKeys.announcementMessage), 600, warnings, RemoteConfigKeys.announcementMessage, title: false);
    var announcementEnabled = reader.boolOf(RemoteConfigKeys.announcementEnabled);
    if (announcementEnabled && announcementId == null) {
      warnings.add('announcement_enabled was turned off because announcement_id is missing or invalid');
      announcementEnabled = false;
    } else if (announcementEnabled && announcementTitle == null && announcementMessage == null) {
      warnings.add('announcement_enabled was turned off because it has no title or message');
      announcementEnabled = false;
    }

    final whatsNewVersion = _token(reader.stringOf(RemoteConfigKeys.whatsNewVersion), warnings, RemoteConfigKeys.whatsNewVersion, max: 32);
    final whatsNewItems = _bullets(reader.stringOf(RemoteConfigKeys.whatsNewBody), warnings);
    var whatsNewEnabled = reader.boolOf(RemoteConfigKeys.whatsNewEnabled);
    if (whatsNewEnabled && (whatsNewVersion == null || whatsNewItems.isEmpty)) {
      warnings.add('whats_new_enabled was turned off because the version or body is missing');
      whatsNewEnabled = false;
    }

    final actionLabel = _optional(reader.stringOf(RemoteConfigKeys.announcementActionLabel), 32, warnings, RemoteConfigKeys.announcementActionLabel, title: true);
    final actionUrl = _url(reader.stringOf(RemoteConfigKeys.announcementActionUrl), warnings, RemoteConfigKeys.announcementActionUrl);
    if ((actionLabel == null) != (actionUrl == null)) {
      warnings.add('announcement action needs both a label and a valid link');
    }

    return ParsedRemoteConfig(
      AppRemoteConfig(
        schemaVersion: schema,
        maintenanceEnabled: reader.boolOf(RemoteConfigKeys.maintenanceEnabled),
        maintenanceTitle: _text(reader.stringOf(RemoteConfigKeys.maintenanceTitle), RemoteConfigDefaults.maintenanceTitle, 80, warnings, RemoteConfigKeys.maintenanceTitle, title: true),
        maintenanceMessage: _text(reader.stringOf(RemoteConfigKeys.maintenanceMessage), RemoteConfigDefaults.maintenanceMessage, 600, warnings, RemoteConfigKeys.maintenanceMessage, title: false),
        maintenanceStartsAt: maintenanceStarts,
        maintenanceEndsAt: maintenanceEnds,
        maintenanceShowRetry: reader.boolOf(RemoteConfigKeys.maintenanceShowRetry),
        forceUpdateEnabled: reader.boolOf(RemoteConfigKeys.forceUpdateEnabled),
        minSupportedVersion: _version(reader.stringOf(RemoteConfigKeys.minSupportedVersion), warnings, RemoteConfigKeys.minSupportedVersion),
        minSupportedBuild: _build(reader.intOf(RemoteConfigKeys.minSupportedBuild), warnings, RemoteConfigKeys.minSupportedBuild),
        softUpdateEnabled: reader.boolOf(RemoteConfigKeys.softUpdateEnabled),
        latestVersion: _version(reader.stringOf(RemoteConfigKeys.latestVersion), warnings, RemoteConfigKeys.latestVersion),
        latestBuild: _build(reader.intOf(RemoteConfigKeys.latestBuild), warnings, RemoteConfigKeys.latestBuild),
        updateTitle: _text(reader.stringOf(RemoteConfigKeys.updateTitle), RemoteConfigDefaults.updateTitle, 80, warnings, RemoteConfigKeys.updateTitle, title: true),
        updateMessage: _text(reader.stringOf(RemoteConfigKeys.updateMessage), RemoteConfigDefaults.updateMessage, 600, warnings, RemoteConfigKeys.updateMessage, title: false),
        forceUpdateTitle: _text(reader.stringOf(RemoteConfigKeys.forceUpdateTitle), RemoteConfigDefaults.forceUpdateTitle, 80, warnings, RemoteConfigKeys.forceUpdateTitle, title: true),
        forceUpdateMessage: _text(reader.stringOf(RemoteConfigKeys.forceUpdateMessage), RemoteConfigDefaults.forceUpdateMessage, 600, warnings, RemoteConfigKeys.forceUpdateMessage, title: false),
        updateButtonLabel: _text(reader.stringOf(RemoteConfigKeys.updateButtonLabel), RemoteConfigDefaults.updateButtonLabel, 24, warnings, RemoteConfigKeys.updateButtonLabel, title: true),
        androidStoreUrl: _url(reader.stringOf(RemoteConfigKeys.androidStoreUrl), warnings, RemoteConfigKeys.androidStoreUrl),
        iosStoreUrl: _url(reader.stringOf(RemoteConfigKeys.iosStoreUrl), warnings, RemoteConfigKeys.iosStoreUrl),
        announcementEnabled: announcementEnabled,
        announcementId: announcementId,
        announcementTitle: announcementTitle ?? 'Announcement',
        announcementMessage: announcementMessage ?? '',
        announcementSeverity: _severity(reader.stringOf(RemoteConfigKeys.announcementSeverity), warnings),
        announcementDismissible: reader.boolOf(RemoteConfigKeys.announcementDismissible),
        announcementActionLabel: actionUrl == null ? null : actionLabel,
        announcementActionUrl: actionLabel == null ? null : actionUrl,
        announcementStartsAt: announcementStarts,
        announcementEndsAt: announcementEnds,
        whatsNewEnabled: whatsNewEnabled,
        whatsNewVersion: whatsNewVersion,
        whatsNewTitle: _text(reader.stringOf(RemoteConfigKeys.whatsNewTitle), RemoteConfigDefaults.whatsNewTitle, 80, warnings, RemoteConfigKeys.whatsNewTitle, title: true),
        whatsNewItems: whatsNewItems,
        guestModeEnabled: reader.boolOf(RemoteConfigKeys.guestModeEnabled),
        advisorEnabled: reader.boolOf(RemoteConfigKeys.advisorEnabled),
        calculatorEnabled: reader.boolOf(RemoteConfigKeys.calculatorEnabled),
        compareEnabled: reader.boolOf(RemoteConfigKeys.compareEnabled),
        pushEnabled: reader.boolOf(RemoteConfigKeys.pushEnabled),
        privacyPolicyUrl: _url(reader.stringOf(RemoteConfigKeys.privacyPolicyUrl), warnings, RemoteConfigKeys.privacyPolicyUrl),
        termsUrl: _url(reader.stringOf(RemoteConfigKeys.termsUrl), warnings, RemoteConfigKeys.termsUrl),
        supportEmail: _email(reader.stringOf(RemoteConfigKeys.supportEmail), warnings),
        helpUrl: _url(reader.stringOf(RemoteConfigKeys.helpUrl), warnings, RemoteConfigKeys.helpUrl),
      ),
      warnings,
    );
  }

  static void _warnWindow(DateTime? start, DateTime? end, String name, List<String> warnings) {
    if (start != null && end != null && !end.isAfter(start)) {
      warnings.add('${name}_ends_at must be after ${name}_starts_at; that window stays closed');
    }
  }

  static String _text(String raw, String fallback, int max, List<String> warnings, String key, {required bool title}) {
    final cleaned = _clean(raw, title: title);
    if (cleaned.isEmpty) return fallback;
    return _clamp(cleaned, max, warnings, key);
  }

  static String? _optional(String raw, int max, List<String> warnings, String key, {required bool title}) {
    final cleaned = _clean(raw, title: title);
    if (cleaned.isEmpty) return null;
    return _clamp(cleaned, max, warnings, key);
  }

  static String _clean(String raw, {required bool title}) {
    final trimmed = raw.trim();
    if (title) return trimmed.replaceAll(RegExp(r'\s+'), ' ');
    return trimmed.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static String _clamp(String value, int max, List<String> warnings, String key) {
    if (value.length <= max) return value;
    warnings.add('$key was shortened to $max characters');
    return '${value.substring(0, max - 1).trimRight()}…';
  }

  static String? _token(String raw, List<String> warnings, String key, {required int max}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final ok = RegExp('^[A-Za-z0-9._\\-]{1,$max}\$').hasMatch(trimmed);
    if (!ok) {
      warnings.add('$key was ignored because it must be 1-$max letters, numbers, dots, dashes, or underscores');
      return null;
    }
    return trimmed;
  }

  static AppVersion? _version(String raw, List<String> warnings, String key) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = AppVersion.tryParse(trimmed);
    if (parsed == null) {
      warnings.add('$key was ignored because it is not a version like 1.2.3');
      return null;
    }
    return parsed;
  }

  static int _build(int raw, List<String> warnings, String key) {
    if (raw < 0) {
      warnings.add('$key was ignored because it is negative');
      return 0;
    }
    return raw;
  }

  static DateTime? _date(RemoteConfigReader reader, String key, List<String> warnings) {
    final raw = reader.stringOf(key).trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      warnings.add('$key was ignored because it is not an ISO-8601 date');
      return null;
    }
    return parsed.toUtc();
  }

  static AnnouncementSeverity _severity(String raw, List<String> warnings) {
    switch (raw.trim().toLowerCase()) {
      case 'success':
        return AnnouncementSeverity.success;
      case 'warning':
        return AnnouncementSeverity.warning;
      case 'critical':
        return AnnouncementSeverity.critical;
      case 'info':
      case '':
        return AnnouncementSeverity.info;
      default:
        warnings.add('announcement_severity was ignored; using info');
        return AnnouncementSeverity.info;
    }
  }

  static List<String> _bullets(String raw, List<String> warnings) {
    final lines = raw.split(RegExp(r'\r?\n')).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    if (lines.length > 8) warnings.add('whats_new_body was shortened to 8 lines');
    return [
      for (final line in lines.take(8))
        line.length <= 140 ? line : '${line.substring(0, 139).trimRight()}…',
    ];
  }

  static String? _url(String raw, List<String> warnings, String key) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    const allowed = {'https', 'http', 'mailto', 'itms-apps', 'market'};
    final hostOk = uri != null && (uri.host.isNotEmpty || uri.scheme == 'mailto');
    if (uri == null || !uri.hasScheme || !allowed.contains(uri.scheme) || !hostOk) {
      warnings.add('$key was ignored because it is not a valid link');
      return null;
    }
    if (uri.scheme == 'mailto' && uri.path.isEmpty) {
      warnings.add('$key was ignored because it is not a valid link');
      return null;
    }
    return trimmed;
  }

  static String? _email(String raw, List<String> warnings) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final ok = RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$').hasMatch(trimmed);
    if (!ok || trimmed.length > 120) {
      warnings.add('support_email was ignored because it is not a valid email');
      return null;
    }
    return trimmed;
  }
}
