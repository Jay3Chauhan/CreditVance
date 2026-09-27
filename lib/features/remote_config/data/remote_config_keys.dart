/// Remote Config parameter names. Keep these stable — the console template
/// and the app both use this list.
class RemoteConfigKeys {
  const RemoteConfigKeys._();

  static const schemaVersion = 'config_schema_version';

  static const maintenanceEnabled = 'maintenance_enabled';
  static const maintenanceTitle = 'maintenance_title';
  static const maintenanceMessage = 'maintenance_message';
  static const maintenanceStartsAt = 'maintenance_starts_at';
  static const maintenanceEndsAt = 'maintenance_ends_at';
  static const maintenanceShowRetry = 'maintenance_show_retry';

  static const forceUpdateEnabled = 'force_update_enabled';
  static const minSupportedVersion = 'min_supported_version';
  static const minSupportedBuild = 'min_supported_build';
  static const softUpdateEnabled = 'soft_update_enabled';
  static const latestVersion = 'latest_version';
  static const latestBuild = 'latest_build';
  static const updateTitle = 'update_title';
  static const updateMessage = 'update_message';
  static const forceUpdateTitle = 'force_update_title';
  static const forceUpdateMessage = 'force_update_message';
  static const updateButtonLabel = 'update_button_label';
  static const androidStoreUrl = 'android_store_url';
  static const iosStoreUrl = 'ios_store_url';

  static const announcementEnabled = 'announcement_enabled';
  static const announcementId = 'announcement_id';
  static const announcementTitle = 'announcement_title';
  static const announcementMessage = 'announcement_message';
  static const announcementSeverity = 'announcement_severity';
  static const announcementDismissible = 'announcement_dismissible';
  static const announcementActionLabel = 'announcement_action_label';
  static const announcementActionUrl = 'announcement_action_url';
  static const announcementStartsAt = 'announcement_starts_at';
  static const announcementEndsAt = 'announcement_ends_at';

  static const whatsNewEnabled = 'whats_new_enabled';
  static const whatsNewVersion = 'whats_new_version';
  static const whatsNewTitle = 'whats_new_title';
  static const whatsNewBody = 'whats_new_body';

  static const guestModeEnabled = 'feature_guest_mode_enabled';
  static const advisorEnabled = 'feature_advisor_enabled';
  static const calculatorEnabled = 'feature_calculator_enabled';
  static const compareEnabled = 'feature_compare_enabled';
  static const pushEnabled = 'feature_push_enabled';

  static const privacyPolicyUrl = 'privacy_policy_url';
  static const termsUrl = 'terms_url';
  static const supportEmail = 'support_email';
  static const helpUrl = 'help_url';
}

class RemoteConfigDefaults {
  const RemoteConfigDefaults._();

  static const maintenanceTitle = "We'll be right back";
  static const maintenanceMessage =
      'Credvert is temporarily unavailable while we make improvements. Cards saved on this device stay here.';
  static const updateTitle = 'A new version is ready';
  static const updateMessage = 'Update Credvert for the latest fixes and improvements. You can keep using this version for now.';
  static const forceUpdateTitle = 'Update required';
  static const forceUpdateMessage =
      'This version of Credvert is no longer supported. Update to keep your wallet and recommendations working.';
  static const updateButtonLabel = 'Update now';
  static const androidStoreUrl = 'https://play.google.com/store/apps/details?id=com.jaychauhan.credvert';
  static const whatsNewTitle = "What's new";

  static Map<String, dynamic> get map => {
        RemoteConfigKeys.schemaVersion: 1,
        RemoteConfigKeys.maintenanceEnabled: false,
        RemoteConfigKeys.maintenanceTitle: maintenanceTitle,
        RemoteConfigKeys.maintenanceMessage: maintenanceMessage,
        RemoteConfigKeys.maintenanceStartsAt: '',
        RemoteConfigKeys.maintenanceEndsAt: '',
        RemoteConfigKeys.maintenanceShowRetry: true,
        RemoteConfigKeys.forceUpdateEnabled: false,
        RemoteConfigKeys.minSupportedVersion: '1.0.0',
        RemoteConfigKeys.minSupportedBuild: 0,
        RemoteConfigKeys.softUpdateEnabled: false,
        RemoteConfigKeys.latestVersion: '1.0.0',
        RemoteConfigKeys.latestBuild: 0,
        RemoteConfigKeys.updateTitle: updateTitle,
        RemoteConfigKeys.updateMessage: updateMessage,
        RemoteConfigKeys.forceUpdateTitle: forceUpdateTitle,
        RemoteConfigKeys.forceUpdateMessage: forceUpdateMessage,
        RemoteConfigKeys.updateButtonLabel: updateButtonLabel,
        RemoteConfigKeys.androidStoreUrl: androidStoreUrl,
        RemoteConfigKeys.iosStoreUrl: '',
        RemoteConfigKeys.announcementEnabled: false,
        RemoteConfigKeys.announcementId: '',
        RemoteConfigKeys.announcementTitle: '',
        RemoteConfigKeys.announcementMessage: '',
        RemoteConfigKeys.announcementSeverity: 'info',
        RemoteConfigKeys.announcementDismissible: true,
        RemoteConfigKeys.announcementActionLabel: '',
        RemoteConfigKeys.announcementActionUrl: '',
        RemoteConfigKeys.announcementStartsAt: '',
        RemoteConfigKeys.announcementEndsAt: '',
        RemoteConfigKeys.whatsNewEnabled: false,
        RemoteConfigKeys.whatsNewVersion: '',
        RemoteConfigKeys.whatsNewTitle: whatsNewTitle,
        RemoteConfigKeys.whatsNewBody: '',
        RemoteConfigKeys.guestModeEnabled: true,
        RemoteConfigKeys.advisorEnabled: true,
        RemoteConfigKeys.calculatorEnabled: true,
        RemoteConfigKeys.compareEnabled: true,
        RemoteConfigKeys.pushEnabled: true,
        RemoteConfigKeys.privacyPolicyUrl: '',
        RemoteConfigKeys.termsUrl: '',
        RemoteConfigKeys.supportEmail: '',
        RemoteConfigKeys.helpUrl: '',
      };
}
