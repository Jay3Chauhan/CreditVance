import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/context_ext.dart';
import 'app_surface.dart';

/// Pill-shaped selectable chip with animated fill.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? leading;
  final Color? color;
  final int? badge;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.leading,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.accent;
    final fg = selected ? tone : c.textSecondary;

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: AppDimensions.fastAnim,
        height: AppDimensions.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? c.tint(tone, c.isDark ? 0.16 : 0.12) : c.surface,
          borderRadius: AppDimensions.roundedFull,
          border: Border.all(color: selected ? c.tint(tone, 0.45) : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
            Text(label, style: context.text.labelMedium!.copyWith(color: fg)),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: tone, borderRadius: AppDimensions.roundedFull),
                child: Text('$badge', style: context.text.labelSmall!.copyWith(color: c.onAccent)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small static label (e.g. "Lifetime free", "Popular").
class AppTag extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool onCard;

  const AppTag({super.key, required this.label, this.color, this.icon, this.onCard = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: onCard ? Colors.white.withValues(alpha: 0.12) : c.tint(tone, c.isDark ? 0.14 : 0.10),
        borderRadius: AppDimensions.roundedXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: tone), const SizedBox(width: 4)],
          Text(
            label,
            style: context.text.labelSmall!.copyWith(color: tone, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling chip row with edge padding.
class ChipStrip extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ChipStrip({super.key, required this.children, this.padding = AppDimensions.screenHorizontal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.chipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}
