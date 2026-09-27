import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'announcement_banner.dart';
import 'remote_config_controller.dart';
import 'status_screen.dart';
import 'update_prompts.dart';

/// Blocks the app for maintenance, forced updates, and critical announcements.
/// Everything else keeps the normal navigation, with a banner and optional sheets.
class AppStatusGate extends StatelessWidget {
  final Widget child;

  const AppStatusGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    if (!remote.ready) return const StartupSplash();
    if (remote.maintenanceActive) return const MaintenanceScreen();
    if (remote.forceUpdate) return const ForceUpdateScreen();
    if (remote.blockingAnnouncement) return const BlockingAnnouncementScreen();

    return Stack(
      children: [
        Column(
          children: [
            const AnnouncementSlot(),
            Expanded(child: child),
          ],
        ),
        const UpdatePromptHost(),
      ],
    );
  }
}
