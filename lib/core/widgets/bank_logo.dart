import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/context_ext.dart';

/// Bank logo on a rounded tile, falling back to the bank's initials.
class BankLogo extends StatelessWidget {
  final String? url;
  final String bankName;
  final double size;

  const BankLogo({super.key, this.url, required this.bankName, this.size = 36});

  String get _initials {
    final words = bankName
        .replaceAll(RegExp(r'\b(bank|card|ltd|limited)\b', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '•';
    if (words.length == 1) return words.first.substring(0, words.first.length.clamp(1, 4)).toUpperCase();
    return words.take(2).map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(size * 0.28);
    final fallback = Center(
      child: Text(
        _initials,
        style: context.text.labelSmall!.copyWith(
          color: c.textSecondary,
          fontSize: size * 0.28,
          letterSpacing: 0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.isDark ? Colors.white : c.surface,
        borderRadius: radius,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.12),
      child: url == null || url!.isEmpty
          ? ColoredBox(color: c.surfaceAlt, child: fallback)
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 150),
              errorWidget: (_, _, _) => fallback,
              placeholder: (_, _) => const SizedBox.shrink(),
            ),
    );
  }
}
