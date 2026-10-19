import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../domain/entities/sms_tracking_status.dart';
import '../providers/expense_provider.dart';
import '../widgets/reject_reason_labels.dart';
import 'sms_consent_screen.dart';

/// Tracking & privacy controls: pause/resume, rescan, sync, permission and
/// one-tap erasure (DPDP withdrawal must be as easy as giving consent).
class SmsTrackingSettingsSheet extends StatelessWidget {
  const SmsTrackingSettingsSheet({super.key});

  /// Presents the sheet.
  static Future<void> show(BuildContext context) {
    HapticsHelper.light();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SmsTrackingSettingsSheet(),
    );
  }

  static final DateFormat _timeFormat = DateFormat('d MMM yyyy, h:mm a');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Consumer<ExpenseProvider>(
        builder: (context, p, _) {
          final scan = p.lastScan;
          final filtered = scan?.rejected.entries.where((e) => e.value > 0).toList() ?? const [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tracking & Privacy', style: AppTypography.headlineLarge.copyWith(color: c.textPrimary)),
                const SizedBox(height: AppDimensions.p16),
                _Row(label: 'SMS reading', value: _trackingLabel(p)),
                _Row(label: 'Records on this device', value: '${p.transactions.length}'),
                _Row(label: 'Waiting to back up', value: '${p.pendingSyncCount}'),
                _Row(
                  label: 'Last backup',
                  value: p.lastSyncedAt == null ? 'Never' : _timeFormat.format(p.lastSyncedAt!),
                ),
                if (scan != null)
                  _Row(
                    label: 'Last scan',
                    value: '${scan.scanned} bank SMS • ${scan.newTransactions} new • ${scan.rejectedCount} filtered',
                  ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.p4),
                  Text(
                    'Filtered: ${filtered.map((e) => '${e.key.shortLabel} ${e.value}').join(' • ')}',
                    style: AppTypography.bodySmall.copyWith(color: c.textTertiary),
                  ),
                ],
                const SizedBox(height: AppDimensions.p16),
                Text(
                  'Only parsed fields (amount, merchant, category, date, bank, last 4 digits) are backed up. '
                  'SMS text, OTPs, full card numbers, CVV and expiry never leave this phone.',
                  style: AppTypography.bodySmall.copyWith(color: c.textTertiary),
                ),
                const SizedBox(height: AppDimensions.p20),
                if (p.isSmsSupported) ..._trackingActions(context, p),
                LuxuryButton(
                  label: 'Back up now',
                  icon: AppIcons.sync,
                  variant: LuxuryButtonVariant.secondary,
                  height: AppDimensions.buttonHeightSm,
                  onPressed: p.syncStatus == ExpenseSyncStatus.syncing ? null : p.syncNow,
                ),
                const SizedBox(height: AppDimensions.p12),
                LuxuryButton(
                  label: 'Delete all spend data',
                  icon: AppIcons.delete,
                  variant: LuxuryButtonVariant.danger,
                  height: AppDimensions.buttonHeightSm,
                  onPressed: () => _confirmDelete(context, p),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _trackingLabel(ExpenseProvider p) {
    if (!p.isSmsSupported) return 'Not available on this platform';
    if (p.isTrackingActive) return 'Active';
    return switch (p.consent.status) {
      SmsConsentStatus.withdrawn => 'Paused',
      SmsConsentStatus.declined || SmsConsentStatus.notAsked => 'Off',
      SmsConsentStatus.granted => 'Permission needed',
    };
  }

  List<Widget> _trackingActions(BuildContext context, ExpenseProvider p) {
    return [
      if (p.isTrackingActive) ...[
        LuxuryButton(
          label: 'Re-scan last 6 months',
          icon: AppIcons.refresh,
          variant: LuxuryButtonVariant.outline,
          height: AppDimensions.buttonHeightSm,
          isLoading: p.isScanning,
          onPressed: p.fullRescan,
        ),
        const SizedBox(height: AppDimensions.p12),
        LuxuryButton(
          label: 'Pause SMS tracking',
          icon: AppIcons.pause,
          variant: LuxuryButtonVariant.secondary,
          height: AppDimensions.buttonHeightSm,
          onPressed: () async {
            await p.pauseTracking();
            if (context.mounted) {
              AppToast.info(context, title: 'Tracking paused', message: 'No new SMS will be read.');
            }
          },
        ),
      ] else
        LuxuryButton(
          label: 'Turn on SMS tracking',
          icon: AppIcons.play,
          height: AppDimensions.buttonHeightSm,
          onPressed: () => SmsConsentScreen.open(context),
        ),
      const SizedBox(height: AppDimensions.p12),
      LuxuryButton(
        label: 'Android permission settings',
        icon: AppIcons.settings,
        variant: LuxuryButtonVariant.secondary,
        height: AppDimensions.buttonHeightSm,
        onPressed: p.openAppSettings,
      ),
      const SizedBox(height: AppDimensions.p12),
    ];
  }

  void _confirmDelete(BuildContext context, ExpenseProvider provider) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
        title: Text('Delete all spend data?', style: AppTypography.headlineMedium.copyWith(color: dialogCtx.colors.textPrimary)),
        content: Text(
          'This erases every parsed transaction, bill and milestone history from this device and requests '
          'deletion from Credvert servers. SMS tracking will be turned off. Your SMS inbox is not touched.',
          style: AppTypography.bodyMedium.copyWith(color: dialogCtx.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: dialogCtx.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              HapticsHelper.heavy();
              await provider.deleteAllData();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              AppToast.success(context, title: 'Data deleted', message: 'All SMS-derived spend data was erased.');
            },
            child: Text('Delete', style: AppTypography.labelLarge.copyWith(color: dialogCtx.colors.danger)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.p4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary))),
          const SizedBox(width: AppDimensions.p12),
          Flexible(
            child: Text(value, style: AppTypography.titleSmall.copyWith(color: context.colors.textPrimary), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
