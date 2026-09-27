import 'package:flutter/foundation.dart';

import 'app_version.dart';

enum AnnouncementSeverity { info, success, warning, critical }

/// Validated Remote Config snapshot. Invalid console values are already
/// dropped or replaced before this object is created.
@immutable
class AppRemoteConfig {
  final int schemaVersion;
  final bool maintenanceEnabled;
  final String maintenanceTitle;
  final String maintenanceMessage;
  final DateTime? maintenanceStartsAt;
  final DateTime? maintenanceEndsAt;
  final bool maintenanceShowRetry;
  final bool forceUpdateEnabled;
  final AppVersion? minSupportedVersion;
  final int minSupportedBuild;
  final bool softUpdateEnabled;
  final AppVersion? latestVersion;
  final int latestBuild;
  final String updateTitle;
  final String updateMessage;
  final String forceUpdateTitle;
  final String forceUpdateMessage;
  final String updateButtonLabel;
  final String? androidStoreUrl;
  final String? iosStoreUrl;
  final bool announcementEnabled;
  final String? announcementId;
  final String announcementTitle;
  final String announcementMessage;
  final AnnouncementSeverity announcementSeverity;
  final bool announcementDismissible;
  final String? announcementActionLabel;
  final String? announcementActionUrl;
  final DateTime? announcementStartsAt;
  final DateTime? announcementEndsAt;
  final bool whatsNewEnabled;
  final String? whatsNewVersion;
  final String whatsNewTitle;
  final List<String> whatsNewItems;
  final bool guestModeEnabled;
  final bool advisorEnabled;
  final bool calculatorEnabled;
  final bool compareEnabled;
  final bool pushEnabled;
  final String? privacyPolicyUrl;
  final String? termsUrl;
  final String? supportEmail;
  final String? helpUrl;

  const AppRemoteConfig({
    required this.schemaVersion,
    required this.maintenanceEnabled,
    required this.maintenanceTitle,
    required this.maintenanceMessage,
    required this.maintenanceStartsAt,
    required this.maintenanceEndsAt,
    required this.maintenanceShowRetry,
    required this.forceUpdateEnabled,
    required this.minSupportedVersion,
    required this.minSupportedBuild,
    required this.softUpdateEnabled,
    required this.latestVersion,
    required this.latestBuild,
    required this.updateTitle,
    required this.updateMessage,
    required this.forceUpdateTitle,
    required this.forceUpdateMessage,
    required this.updateButtonLabel,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
    required this.announcementEnabled,
    required this.announcementId,
    required this.announcementTitle,
    required this.announcementMessage,
    required this.announcementSeverity,
    required this.announcementDismissible,
    required this.announcementActionLabel,
    required this.announcementActionUrl,
    required this.announcementStartsAt,
    required this.announcementEndsAt,
    required this.whatsNewEnabled,
    required this.whatsNewVersion,
    required this.whatsNewTitle,
    required this.whatsNewItems,
    required this.guestModeEnabled,
    required this.advisorEnabled,
    required this.calculatorEnabled,
    required this.compareEnabled,
    required this.pushEnabled,
    required this.privacyPolicyUrl,
    required this.termsUrl,
    required this.supportEmail,
    required this.helpUrl,
  });

  String? get supportMailto => supportEmail == null ? null : 'mailto:$supportEmail';

  String get softUpdateKey => '${latestVersion?.label ?? '0.0.0'}+$latestBuild';

  bool get announcementBlocks => announcementSeverity == AnnouncementSeverity.critical && !announcementDismissible;

  bool maintenanceActive(DateTime now) =>
      maintenanceEnabled && windowIsOpen(startsAt: maintenanceStartsAt, endsAt: maintenanceEndsAt, now: now);

  bool announcementActive(DateTime now) =>
      announcementEnabled &&
      announcementId != null &&
      windowIsOpen(startsAt: announcementStartsAt, endsAt: announcementEndsAt, now: now);

  bool forceUpdateRequired(AppVersion current) {
    if (!forceUpdateEnabled) return false;
    final minimum = minSupportedVersion;
    if (minimum != null && current.compareTo(minimum) < 0) return true;
    if (minSupportedBuild > 0 && current.build > 0 && current.build < minSupportedBuild) return true;
    return false;
  }

  bool softUpdateAvailable(AppVersion current) {
    if (!softUpdateEnabled || forceUpdateRequired(current)) return false;
    final latest = latestVersion;
    if (latest != null && current.compareTo(latest) < 0) return true;
    if (latestBuild > 0 && current.build > 0 && current.build < latestBuild) return true;
    return false;
  }

  String? storeUrlFor(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) return iosStoreUrl;
    return androidStoreUrl;
  }
}

/// A window with an end before its start is treated as misconfigured and closed.
bool windowIsOpen({DateTime? startsAt, DateTime? endsAt, required DateTime now}) {
  if (startsAt != null && endsAt != null && !endsAt.isAfter(startsAt)) return false;
  if (startsAt != null && now.isBefore(startsAt)) return false;
  if (endsAt != null && !now.isBefore(endsAt)) return false;
  return true;
}
