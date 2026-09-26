import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_typography.dart';

/// Circular countdown driven by a seconds [ValueListenable].
class CountdownRing extends StatelessWidget {
  final ValueListenable<int> remaining;
  final int total;
  final double size;
  final Color color;
  final Color trackColor;

  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 30,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: remaining,
      builder: (context, secs, _) {
        final progress = total <= 0 ? 0.0 : (secs / total).clamp(0.0, 1.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 900),
                builder: (_, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 2.4,
                  color: color,
                  backgroundColor: trackColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('$secs', style: AppTypography.numeric(size * 0.34, color: color)),
            ],
          ),
        );
      },
    );
  }
}
