import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/firebase/analytics_service.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/widgets/app_surface.dart';
import 'open_remote_link.dart';
import 'remote_config_controller.dart';
import 'status_screen.dart';

class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final remote = context.read<RemoteConfigController>();
      remote.logOnce('announcement_${remote.config.announcementId}', 'announcement_shown', {
        'id': remote.config.announcementId ?? '',
        'severity': remote.config.announcementSeverity.name,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    final config = remote.config;
    final colors = context.colors;
    final tone = severityColor(context, config.announcementSeverity);
    final action = config.announcementActionUrl;

    return Material(
      color: colors.canvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: AppSurface(
            tintColor: tone,
            tone: SurfaceTone.accent,
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconHalo(icon: AppIcons.megaphone, color: tone, size: 32, iconSize: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.announcementTitle, style: context.text.titleSmall),
                      if (config.announcementMessage.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(config.announcementMessage, style: context.text.bodySmall, maxLines: 4, overflow: TextOverflow.ellipsis),
                      ],
                      if (action != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: tone,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              AnalyticsService.log('announcement_opened', {'id': config.announcementId ?? ''});
                              openRemoteLink(context, action);
                            },
                            child: Text(config.announcementActionLabel ?? 'Open'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (config.announcementDismissible)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: remote.dismissAnnouncement,
                    icon: Icon(AppIcons.close, size: 16, color: colors.textTertiary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the banner from claiming space when there is nothing to show.
class AnnouncementSlot extends StatelessWidget {
  const AnnouncementSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final show = context.select<RemoteConfigController, bool>((remote) => remote.bannerAnnouncement);
    if (!show) return const SizedBox.shrink();
    return const AnnouncementBanner();
  }
}
