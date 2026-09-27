import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/firebase/analytics_service.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../domain/app_remote_config.dart';
import 'open_remote_link.dart';
import 'remote_config_controller.dart';

class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconHalo(icon: AppIcons.sparkles, size: 64, iconSize: 28, circle: true, color: colors.accent)
                .animate()
                .scale(begin: const Offset(0.86, 0.86), duration: AppDimensions.mediumAnim, curve: Curves.easeOutBack),
            const SizedBox(height: AppDimensions.p16),
            Text(AppStrings.appName, style: context.text.headlineMedium),
            const SizedBox(height: 4),
            Text(AppStrings.appTagline, style: context.text.bodySmall),
            const SizedBox(height: 28),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RemoteConfigController>().logOnce('maintenance', 'maintenance_shown');
    });
  }

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    final config = remote.config;
    final ends = config.maintenanceEndsAt;
    return StatusScreen(
      icon: AppIcons.construction,
      color: context.colors.warning,
      title: config.maintenanceTitle,
      message: config.maintenanceMessage,
      footnote: ends == null ? null : 'Expected back ${DateFormat('d MMM, h:mm a').format(ends.toLocal())}',
      primary: config.maintenanceShowRetry
          ? StatusAction(
              label: 'Try again',
              icon: AppIcons.refresh,
              loading: remote.refreshing,
              onPressed: remote.refreshing ? null : () => remote.refresh(userInitiated: true),
            )
          : null,
      secondary: supportAction(context, config),
    );
  }
}

class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final remote = context.read<RemoteConfigController>();
      remote.logOnce('force_update', 'force_update_shown', {'version': remote.versionLabel});
    });
  }

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    final config = remote.config;
    final store = config.storeUrlFor(Theme.of(context).platform);
    return StatusScreen(
      icon: AppIcons.download,
      color: context.colors.accent,
      title: config.forceUpdateTitle,
      message: config.forceUpdateMessage,
      footnote: _versionFootnote(remote, requiredLabel: config.minSupportedVersion?.label),
      extra: store == null ? 'The store link is not set up yet. Contact support if you need the update.' : null,
      primary: store == null
          ? null
          : StatusAction(
              label: config.updateButtonLabel,
              icon: AppIcons.arrowUpRight,
              onPressed: () {
                AnalyticsService.log('update_opened', {'kind': 'force'});
                openRemoteLink(context, store);
              },
            ),
      secondary: supportAction(context, config),
    );
  }
}

class BlockingAnnouncementScreen extends StatefulWidget {
  const BlockingAnnouncementScreen({super.key});

  @override
  State<BlockingAnnouncementScreen> createState() => _BlockingAnnouncementScreenState();
}

class _BlockingAnnouncementScreenState extends State<BlockingAnnouncementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final remote = context.read<RemoteConfigController>();
      remote.logOnce('announcement_block_${remote.config.announcementId}', 'announcement_shown', {
        'id': remote.config.announcementId ?? '',
        'severity': remote.config.announcementSeverity.name,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    final config = remote.config;
    final action = config.announcementActionUrl;
    return StatusScreen(
      icon: AppIcons.megaphone,
      color: severityColor(context, config.announcementSeverity),
      title: config.announcementTitle,
      message: config.announcementMessage,
      primary: action == null
          ? null
          : StatusAction(
              label: config.announcementActionLabel ?? 'Open',
              icon: AppIcons.arrowUpRight,
              onPressed: () {
                AnalyticsService.log('announcement_opened', {'id': config.announcementId ?? ''});
                openRemoteLink(context, action);
              },
            ),
      secondary: supportAction(context, config),
    );
  }
}

class StatusAction {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const StatusAction({required this.label, required this.icon, required this.onPressed, this.loading = false});
}

class StatusScreen extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? footnote;
  final String? extra;
  final StatusAction? primary;
  final StatusAction? secondary;

  const StatusScreen({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.footnote,
    this.extra,
    this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.p24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconHalo(icon: icon, color: color, size: 72, iconSize: 30, circle: true)
                      .animate()
                      .scale(begin: const Offset(0.86, 0.86), duration: AppDimensions.mediumAnim, curve: Curves.easeOutBack),
                  const SizedBox(height: AppDimensions.p20),
                  Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.p8),
                    Text(
                      message,
                      style: context.text.bodyMedium!.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (footnote != null) ...[
                    const SizedBox(height: AppDimensions.p12),
                    Text(footnote!, style: context.text.labelMedium!.copyWith(color: colors.textTertiary), textAlign: TextAlign.center),
                  ],
                  if (extra != null) ...[
                    const SizedBox(height: AppDimensions.p12),
                    Text(extra!, style: context.text.bodySmall, textAlign: TextAlign.center),
                  ],
                  if (primary != null) ...[
                    const SizedBox(height: AppDimensions.p24),
                    AppButton(
                      label: primary!.label,
                      icon: primary!.icon,
                      trailingIcon: true,
                      isLoading: primary!.loading,
                      onPressed: primary!.onPressed,
                    ),
                  ],
                  if (secondary != null) ...[
                    const SizedBox(height: 8),
                    AppButton.ghost(label: secondary!.label, icon: secondary!.icon, onPressed: secondary!.onPressed),
                  ],
                ],
              ).animate().fadeIn(duration: AppDimensions.mediumAnim),
            ),
          ),
        ),
      ),
    );
  }
}

StatusAction? supportAction(BuildContext context, AppRemoteConfig config) {
  final mailto = config.supportMailto;
  if (mailto == null) return null;
  return StatusAction(label: 'Contact support', icon: AppIcons.mail, onPressed: () => openRemoteLink(context, mailto));
}

String _versionFootnote(RemoteConfigController remote, {String? requiredLabel}) {
  final installed = 'Installed ${remote.versionLabel}';
  if (requiredLabel == null) return installed;
  return '$installed · Required $requiredLabel';
}

Color severityColor(BuildContext context, AnnouncementSeverity severity) {
  final colors = context.colors;
  return switch (severity) {
    AnnouncementSeverity.success => colors.success,
    AnnouncementSeverity.warning => colors.warning,
    AnnouncementSeverity.critical => colors.danger,
    AnnouncementSeverity.info => colors.info,
  };
}
