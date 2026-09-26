import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

/// Number that tweens smoothly between values (₹ amounts or percentages).
class AnimatedAmount extends StatelessWidget {
  final double value;
  final TextStyle style;
  final bool isPercent;
  final bool compact;
  final String prefix;
  final Duration duration;

  const AnimatedAmount({
    super.key,
    required this.value,
    required this.style,
    this.isPercent = false,
    this.compact = false,
    this.prefix = '',
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final text = isPercent
            ? '${v.toStringAsFixed(v.abs() >= 10 ? 1 : 2)}%'
            : compact
                ? CurrencyFormatter.compact(v)
                : CurrencyFormatter.format(v);
        return Text('$prefix$text', style: style, maxLines: 1, overflow: TextOverflow.fade, softWrap: false);
      },
    );
  }
}
