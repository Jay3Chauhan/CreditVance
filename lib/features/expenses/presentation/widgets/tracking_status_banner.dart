import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../domain/entities/sms_tracking_status.dart';
import '../providers/expense_provider.dart';
import '../screens/sms_consent_screen.dart';

/// Snapshot of the tracking/sync fields the banner depends on (for Selector equality).
@immutable
class _BannerData {
  final bool supported;
  final bool needsConsent;
  final SmsConsentStatus consent;
  final SmsPermissionStatus permission;
  final ExpenseSyncStatus sync;
  final bool scanning;
  final DateTime? lastSynced;
  final int pending;

  const _BannerData({
    required this.supported,
    required this.needsConsent,
    required this.consent,
    required this.permission,
    required this.sync,
    required this.scanning,
    required this.lastSynced,
    required this.pending,
  });

  @override
  bool operator ==(Object other) =>
      other is _BannerData &&
      other.supported == supported &&
      other.needsConsent == needsConsent &&
      other.consent == consent &&
      other.permission == permission &&
      other.sync == sync &&
      other.scanning == scanning &&
      other.lastSynced == lastSynced &&
      other.pending == pending;

  @override
  int get hashCode => Object.hash(supported, needsConsent, consent, permission, sync, scanning, lastSynced, pending);
}

/// Top-of-screen status: consent prompt, permission recovery, iOS notice or sync health.
class TrackingStatusBanner extends StatelessWidget {
  const TrackingStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, _BannerData>(
      selector: (_, p) => _BannerData(
        supported: p.isSmsSupported,
        needsConsent: p.needsConsentDecision,
        consent: p.consent.status,
        permission: p.permission,
        sync: p.syncStatus,
        scanning: p.isScanning,
        lastSynced: p.lastSyncedAt,
        pending: p.pendingSyncCount,
      ),
      builder: (context, data, _) {
        if (!data.supported) {
          return const _NoticeCard(
            icon: AppIcons.info,
            accent: AppColors.sapphireLight,
            title: 'SMS reading is Android-only',
            message: AppStrings.smsIosNotice,
          );
        }
        if (data.needsConsent || data.consent == SmsConsentStatus.declined) {
          return const SmsConsentPromptCard();
        }
        if (data.consent == SmsConsentStatus.withdrawn) {
          return _NoticeCard(
            icon: AppIcons.pause,
            accent: AppColors.amber,
            title: 'SMS tracking is paused',
            message: 'New bank SMS are not being read. Your existing history stays on this device.',
            actionLabel: 'Resume tracking',
            onAction: () => SmsConsentScreen.open(context),
          );
        }
        if (data.permission == SmsPermissionStatus.permanentlyDenied ||
            data.permission == SmsPermissionStatus.denied) {
          final permanent = data.permission == SmsPermissionStatus.permanentlyDenied;
          return _NoticeCard(
            icon: AppIcons.warning,
            accent: AppColors.rose,
            title: 'SMS permission is off',
            message: permanent
                ? 'Allow SMS access in system Settings → Permissions to resume automatic tracking.'
                : 'Allow SMS access so card alerts can be parsed on this device.',
            actionLabel: permanent ? 'Open Settings' : 'Allow access',
            onAction: () async {
              final provider = context.read<ExpenseProvider>();
              if (permanent) {
                await provider.openAppSettings();
              } else {
                await provider.grantConsentAndEnable();
              }
            },
          );
        }
        return _SyncStatusRow(data: data);
      },
    );
  }
}

/// Inline onboarding card that leads to the full prominent-disclosure screen.
class SmsConsentPromptCard extends StatelessWidget {
  const SmsConsentPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LuxuryGlassCard(
      border: Border.all(color: AppColors.borderGlow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.sms, color: AppColors.gold, size: AppDimensions.iconLg),
              const SizedBox(width: AppDimensions.p12),
              Expanded(child: Text(AppStrings.smsConsentTitle, style: AppTypography.headlineMedium)),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Text(
            'CardSage reads only bank credit card alerts, parses them on this phone and never uploads the SMS text.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.p16),
          LuxuryButton(
            label: 'Set up SMS tracking',
            icon: AppIcons.shieldCheck,
            onPressed: () => SmsConsentScreen.open(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.mediumAnim).slideY(begin: 0.06, end: 0);
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NoticeCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LuxuryGlassCard(
      border: Border.all(color: accent.withValues(alpha: 0.4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: AppDimensions.iconMd),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: AppDimensions.p4),
                Text(message, style: AppTypography.bodyMedium),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: () {
                      HapticsHelper.light();
                      onAction!();
                    },
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.mediumAnim);
  }
}

class _SyncStatusRow extends StatelessWidget {
  final _BannerData data;

  const _SyncStatusRow({required this.data});

  static final DateFormat _timeFormat = DateFormat('d MMM, h:mm a');

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = switch (data.sync) {
      _ when data.scanning => (AppIcons.sms, AppColors.goldLight, 'Reading new bank SMS on device…'),
      ExpenseSyncStatus.syncing => (AppIcons.sync, AppColors.sapphireLight, 'Backing up parsed spends…'),
      ExpenseSyncStatus.synced => (
          AppIcons.cloudDone,
          AppColors.emeraldLight,
          data.lastSynced == null ? 'Backed up' : 'Backed up ${_timeFormat.format(data.lastSynced!)}',
        ),
      ExpenseSyncStatus.offline => (AppIcons.cloudOff, AppColors.textSecondary, 'Offline — ${data.pending} pending'),
      ExpenseSyncStatus.signedOut => (AppIcons.user, AppColors.amber, 'Sign in to back up parsed spends'),
      ExpenseSyncStatus.unavailable => (AppIcons.lock, AppColors.textSecondary, 'On-device mode — cloud backup coming soon'),
      ExpenseSyncStatus.serverError => (AppIcons.alertCircle, AppColors.rose, 'Backup failed — will retry'),
      ExpenseSyncStatus.idle => (AppIcons.shieldCheck, AppColors.emeraldLight, 'Tracking active • parsed on device'),
    };

    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconSm, color: color),
        const SizedBox(width: AppDimensions.p8),
        Expanded(child: Text(label, style: AppTypography.labelSmall.copyWith(color: color))),
        if (data.scanning || data.sync == ExpenseSyncStatus.syncing)
          const SizedBox(
            width: AppDimensions.iconSm,
            height: AppDimensions.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
          ),
      ],
    );
  }
}
