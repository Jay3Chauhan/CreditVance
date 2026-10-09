import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/context_ext.dart';
import 'app_surface.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p24, AppDimensions.p16, AppDimensions.p10),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
          if (actionLabel != null)
            PressableScale(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(actionLabel!, style: context.text.labelMedium!.copyWith(color: c.accent)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small uppercase overline label.
class Overline extends StatelessWidget {
  final String text;
  final Color? color;
  const Overline(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.text.labelSmall!.copyWith(color: color ?? context.colors.textTertiary, letterSpacing: 1.1),
    );
  }
}
