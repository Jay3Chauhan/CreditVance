import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/firebase/analytics_service.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_surface.dart';
import 'open_remote_link.dart';
import 'remote_config_controller.dart';

class UpdatePromptHost extends StatefulWidget {
  const UpdatePromptHost({super.key});

  @override
  State<UpdatePromptHost> createState() => _UpdatePromptHostState();
}

class _UpdatePromptHostState extends State<UpdatePromptHost> {
  bool _busy = false;
  bool _queued = false;
  String? _presentedSoft;
  String? _presentedWhats;
  late final RemoteConfigController _remote;

  @override
  void initState() {
    super.initState();
    _remote = context.read<RemoteConfigController>();
    _remote.addListener(_schedule);
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedule());
  }

  @override
  void dispose() {
    _remote.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    if (!mounted) return;
    if (_busy) {
      _queued = true;
      return;
    }
    final remote = context.read<RemoteConfigController>();
    if (!remote.softUpdate && !remote.whatsNew) return;
    _present();
  }

  Future<void> _present() async {
    _busy = true;
    try {
      final remote = context.read<RemoteConfigController>();
      if (remote.softUpdate && _presentedSoft != remote.config.softUpdateKey) {
        _presentedSoft = remote.config.softUpdateKey;
        remote.logOnce('soft_${remote.config.softUpdateKey}', 'soft_update_shown', {'version': remote.config.softUpdateKey});
        await showAppSheet<void>(context, builder: (ctx) => const _SoftUpdateSheet());
      }
      if (!mounted) return;
      final next = context.read<RemoteConfigController>();
      final whatsVersion = next.config.whatsNewVersion;
      if (next.whatsNew && !next.softUpdate && whatsVersion != null && _presentedWhats != whatsVersion) {
        _presentedWhats = whatsVersion;
        next.logOnce('whats_$whatsVersion', 'whats_new_shown', {'version': whatsVersion});
        await showAppSheet<void>(context, builder: (ctx) => const _WhatsNewSheet());
      }
    } finally {
      _busy = false;
      if (_queued && mounted) {
        _queued = false;
        _schedule();
      }
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SoftUpdateSheet extends StatelessWidget {
  const _SoftUpdateSheet();

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    final config = remote.config;
    final colors = context.colors;
    final store = config.storeUrlFor(Theme.of(context).platform);
    final latest = config.latestVersion?.label;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconHalo(icon: AppIcons.download, color: colors.accent, size: 44, iconSize: 20, circle: true),
            const SizedBox(height: 14),
            Text(config.updateTitle, style: context.text.headlineSmall),
            const SizedBox(height: 8),
            Text(config.updateMessage, style: context.text.bodyMedium),
            const SizedBox(height: 12),
            Text(
              latest == null ? 'Installed ${remote.versionLabel}' : 'Installed ${remote.versionLabel} · Latest $latest',
              style: context.text.labelMedium!.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: 18),
            if (store != null)
              AppButton(
                label: config.updateButtonLabel,
                icon: AppIcons.arrowUpRight,
                trailingIcon: true,
                onPressed: () {
                  AnalyticsService.log('update_opened', {'kind': 'soft'});
                  openRemoteLink(context, store);
                },
              )
            else
              Text('The store link is not set up yet.', style: context.text.bodySmall),
            const SizedBox(height: 4),
            AppButton.ghost(
              label: 'Not now',
              expand: true,
              onPressed: () async {
                await context.read<RemoteConfigController>().dismissSoftUpdate();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNewSheet extends StatelessWidget {
  const _WhatsNewSheet();

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    final config = remote.config;
    final colors = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconHalo(icon: AppIcons.rocket, color: colors.accent, size: 44, iconSize: 20, circle: true),
            const SizedBox(height: 14),
            Text(config.whatsNewTitle, style: context.text.headlineSmall),
            const SizedBox(height: 12),
            for (final item in config.whatsNewItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(AppIcons.checkCircle, size: 14, color: colors.success),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: context.text.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Got it',
              onPressed: () async {
                await context.read<RemoteConfigController>().dismissWhatsNew();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
