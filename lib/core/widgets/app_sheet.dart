import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/context_ext.dart';
import 'app_button.dart';
import 'app_surface.dart';

/// Opens a themed modal bottom sheet, width-capped on tablets.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: builder,
  );
}

/// Confirmation sheet. Resolves to true when confirmed.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData? icon,
  bool destructive = false,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (ctx) {
      final c = ctx.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconHalo(icon: icon, color: destructive ? c.danger : c.accent, size: 52, iconSize: 24, circle: true),
              const SizedBox(height: AppDimensions.p14),
            ],
            Text(title, style: ctx.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.p8),
            Text(message, style: ctx.text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.p24),
            AppButton(
              label: confirmLabel,
              variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: AppDimensions.p8),
            AppButton.outline(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

/// Standard sheet header row (title + optional subtitle).
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SheetHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
