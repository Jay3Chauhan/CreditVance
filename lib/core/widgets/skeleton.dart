import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_dimensions.dart';
import '../utils/context_ext.dart';

/// Shimmering placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppDimensions.roundedSm,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: borderRadius),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat())
        .shimmer(duration: 1400.ms, color: c.isDark ? Colors.white10 : Colors.white70);
  }
}

/// Skeleton for a list row with a leading square and two text lines.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SkeletonBox(width: 64, height: 42),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
