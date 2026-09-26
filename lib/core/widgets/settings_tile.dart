import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../utils/context_ext.dart';
import '../utils/haptics_helper.dart';
import 'app_surface.dart';
import 'section_header.dart';

/// Grouped, rounded list of settings rows with hairline dividers.
class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final String? footer;

  const SettingsGroup({super.key, this.title, required this.children, this.footer});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(height: 1, thickness: 1, indent: 56, color: c.border));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, AppDimensions.p20, 4, AppDimensions.p8),
            child: Overline(title!),
          ),
        AppSurface(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppDimensions.roundedLg,
            child: Column(children: rows),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(footer!, style: context.text.bodySmall),
          ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? value;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.value,
    this.onTap,
    this.iconColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = destructive ? c.danger : (iconColor ?? c.textSecondary);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticsHelper.selection();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconHalo(icon: icon, color: tone, size: 30, iconSize: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall!.copyWith(color: destructive ? c.danger : c.textPrimary),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: context.text.bodySmall),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(value!, style: context.text.labelMedium!.copyWith(color: c.textTertiary)),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (trailing == null && onTap != null) ...[
                const SizedBox(width: 6),
                Icon(AppIcons.chevronRight, size: 14, color: c.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Transform.scale(
        scale: 0.82,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged == null
              ? null
              : (v) {
                  HapticsHelper.selection();
                  onChanged!(v);
                },
        ),
      ),
    );
  }
}
