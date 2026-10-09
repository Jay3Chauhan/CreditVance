import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/context_ext.dart';
import 'app_surface.dart';

enum AppButtonVariant { primary, tonal, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool trailingIcon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool compact;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon = false,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.compact = false,
    this.expand = true,
  });

  const AppButton.tonal({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.compact = false,
    this.expand = true,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.compact = false,
    this.expand = true,
  }) : variant = AppButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.compact = true,
    this.expand = false,
  }) : variant = AppButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !isLoading;

    final (Color bg, Color fg, Color border) = switch (variant) {
      AppButtonVariant.primary => (c.textPrimary, c.canvas, Colors.transparent),
      AppButtonVariant.tonal => (c.tint(c.accent, c.isDark ? 0.16 : 0.12), c.accent, Colors.transparent),
      AppButtonVariant.outline => (Colors.transparent, c.textPrimary, c.borderStrong),
      AppButtonVariant.ghost => (Colors.transparent, c.textSecondary, Colors.transparent),
      AppButtonVariant.danger => (c.tint(c.danger, 0.12), c.danger, Colors.transparent),
    };

    final height = compact ? AppDimensions.buttonHeightSm : AppDimensions.buttonHeight;
    final textStyle = (compact ? context.text.labelMedium : context.text.labelLarge)!.copyWith(color: fg);
    final iconWidget = icon == null ? null : Icon(icon, size: compact ? 16 : 18, color: fg);

    final content = AnimatedSwitcher(
      duration: AppDimensions.fastAnim,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconWidget != null && !trailingIcon) ...[iconWidget, const SizedBox(width: 8)],
                Flexible(child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis)),
                if (iconWidget != null && trailingIcon) ...[const SizedBox(width: 8), iconWidget],
              ],
            ),
    );

    return AnimatedOpacity(
      duration: AppDimensions.fastAnim,
      opacity: enabled || isLoading ? 1 : 0.45,
      child: PressableScale(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2.6),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

/// Small circular icon button used in headers and on cards.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final bool filled;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.filled = true,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = PressableScale(
      onTap: onPressed,
      pressedScale: 0.9,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? c.surfaceAlt : Colors.transparent,
          shape: BoxShape.circle,
          border: filled ? Border.all(color: c.border) : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size * 0.47, color: color ?? c.textPrimary),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
