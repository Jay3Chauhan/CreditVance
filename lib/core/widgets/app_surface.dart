import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/context_ext.dart';
import '../utils/haptics_helper.dart';

/// Scales its child down slightly while pressed.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

/// Owns only the press animation controller.
class _PressableScaleState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: widget.pressedScale)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticsHelper.selection();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticsHelper.medium();
              widget.onLongPress!();
            },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

enum SurfaceTone { base, alt, high, accent, outline }

/// The app's primary container: themed surface, hairline border, optional
/// press feedback.
class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final SurfaceTone tone;
  final Color? tintColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool elevated;
  final Gradient? gradient;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = AppDimensions.cardPadding,
    this.borderRadius = AppDimensions.roundedLg,
    this.tone = SurfaceTone.base,
    this.tintColor,
    this.onTap,
    this.onLongPress,
    this.elevated = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = tintColor;
    final Color fill;
    Color borderColor = c.border;
    switch (tone) {
      case SurfaceTone.base:
        fill = c.surface;
      case SurfaceTone.alt:
        fill = c.surfaceAlt;
      case SurfaceTone.high:
        fill = c.surfaceHigh;
      case SurfaceTone.accent:
        fill = c.tint(tint ?? c.accent, c.isDark ? 0.10 : 0.08);
        borderColor = c.tint(tint ?? c.accent, 0.28);
      case SurfaceTone.outline:
        fill = Colors.transparent;
        borderColor = c.borderStrong;
    }

    final box = AnimatedContainer(
      duration: AppDimensions.mediumAnim,
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: elevated
            ? [BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -8)]
            : null,
      ),
      child: child,
    );

    if (onTap == null && onLongPress == null) return box;
    return PressableScale(onTap: onTap, onLongPress: onLongPress, child: box);
  }
}

/// Circular / rounded icon container with a soft tinted fill.
class IconHalo extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;
  final bool circle;

  const IconHalo({
    super.key,
    required this.icon,
    this.color,
    this.size = 36,
    this.iconSize = 18,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.tint(tone, c.isDark ? 0.14 : 0.10),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: tone),
    );
  }
}

/// Constrains content width and centers it on wide screens.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({super.key, required this.child, this.maxWidth = AppDimensions.contentMaxWidth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
