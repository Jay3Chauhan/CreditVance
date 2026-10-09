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

  /// Formats an amount in [currencyCode]; INR uses the Indian ₹ grouping.
  static String formatWithCode(num amount, String currencyCode, {bool showDecimals = false}) {
    if (currencyCode == 'INR') return format(amount, showDecimals: showDecimals);
    return NumberFormat.simpleCurrency(name: currencyCode, decimalDigits: showDecimals ? 2 : 0).format(amount);
  }

  /// Compact Indian notation for chart labels (₹950, ₹12.5K, ₹3.2L, ₹1.1Cr).
  static String formatCompact(num amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    String trim(double v) => v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.0', '');
    if (abs >= 10000000) return '$sign₹${trim(abs / 10000000)}Cr';
    if (abs >= 100000) return '$sign₹${trim(abs / 100000)}L';
    if (abs >= 1000) return '$sign₹${trim(abs / 1000)}K';
    return '$sign₹${abs.toStringAsFixed(0)}';
  }

  /// Formats percentage rate (e.g. 5.0% or 3.33%)
  static String formatPercentage(double percent) {
    if (percent == percent.roundToDouble()) {
      return '${percent.toInt()}%';
    }
    return '${percent.toStringAsFixed(1)}%';
  }
}
