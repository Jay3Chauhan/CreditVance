import 'package:intl/intl.dart';

/// Formatter for currency and percentages.
class CurrencyFormatter {
  const CurrencyFormatter._();

  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats amount into Indian currency format (e.g. ₹50,000)
  static String format(num amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrDecimalFormatter.format(amount);
    }
    return _inrFormatter.format(amount);
  }

  /// Indian short form: ₹950, ₹12.5K, ₹3.2L, ₹1.1Cr.
  static String compact(num amount) {
    final a = amount.abs();
    final sign = amount < 0 ? '-' : '';
    String trim(double v) => v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    if (a >= 1e7) return '$sign₹${trim(a / 1e7)}Cr';
    if (a >= 1e5) return '$sign₹${trim(a / 1e5)}L';
    if (a >= 1e3) return '$sign₹${trim(a / 1e3)}K';
    return '$sign₹${a.toStringAsFixed(0)}';
  }

  /// Formats percentage rate (e.g. 5.0% or 3.33%)
  static String formatPercentage(double percent) {
    if (percent == percent.roundToDouble()) {
      return '${percent.toInt()}%';
    }
    return '${percent.toStringAsFixed(1)}%';
  }
}
