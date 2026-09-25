import 'package:flutter/services.dart';

/// Card formatting, validation, and network identification utilities.
class CardFormatter {
  const CardFormatter._();

  /// Masks card number, showing only the last 4 digits (e.g., "•••• •••• •••• 4321")
  static String maskCardNumber(String last4) {
    final clean = last4.replaceAll(RegExp(r'\D'), '');
    final suffix = clean.length > 4 ? clean.substring(clean.length - 4) : clean.padLeft(4, '•');
    return '•••• •••• •••• $suffix';
  }

  /// Formats raw 15 or 16 digit PAN into spaced chunks: 4532 1123 4567 8901 or 3712 123456 12345
  static String formatFullPan(String pan) {
    final clean = pan.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('34') || clean.startsWith('37')) {
      // Amex: 4-6-5
      final part1 = clean.length >= 4 ? clean.substring(0, 4) : clean;
      final part2 = clean.length > 4 ? (clean.length >= 10 ? clean.substring(4, 10) : clean.substring(4)) : '';
      final part3 = clean.length > 10 ? (clean.length >= 15 ? clean.substring(10, 15) : clean.substring(10)) : '';
      return [part1, part2, part3].where((s) => s.isNotEmpty).join(' ');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  /// Detects payment network from prefix digits
  static String detectNetwork(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith(RegExp(r'^(5[1-5]|2[2-7])'))) return 'Mastercard';
    if (clean.startsWith(RegExp(r'^(34|37)'))) return 'American Express';
    if (clean.startsWith(RegExp(r'^(60|65|81|82)'))) return 'RuPay';
    if (clean.startsWith(RegExp(r'^(30|36|38)'))) return 'Diners Club';
    return 'Credit Card';
  }

  /// Validates card PAN via Luhn algorithm and expected length
  static bool validateCardNumber(String pan) {
    final clean = pan.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 13 || clean.length > 19) return false;

    // Luhn algorithm check
    int sum = 0;
    bool alternate = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int digit = int.parse(clean[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  /// Validates MM/YY expiry date
  static bool validateExpiry(String expiry) {
    final clean = expiry.trim();
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(clean)) {
      return false;
    }

    final parts = clean.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null) return false;

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    return true;
  }

  /// Validates CVV length (4 for Amex, 3 for other networks)
  static bool validateCvv(String cvv, {String? network}) {
    final clean = cvv.replaceAll(RegExp(r'\D'), '');
    final isAmex = network != null && network.toLowerCase().contains('amex') ||
        network != null && network.toLowerCase().contains('american');
    if (isAmex) {
      return clean.length == 4;
    }
    return clean.length == 3 || clean.length == 4;
  }
}

/// TextInputFormatter for formatting card numbers in real-time as user types
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final clean = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final isAmex = clean.startsWith('34') || clean.startsWith('37');
    final maxDigits = isAmex ? 15 : 16;
    final trimmed = clean.length > maxDigits ? clean.substring(0, maxDigits) : clean;

    String formatted;
    if (isAmex) {
      final part1 = trimmed.length >= 4 ? trimmed.substring(0, 4) : trimmed;
      final part2 = trimmed.length > 4 ? (trimmed.length >= 10 ? trimmed.substring(4, 10) : trimmed.substring(4)) : '';
      final part3 = trimmed.length > 10 ? (trimmed.length >= 15 ? trimmed.substring(10, 15) : trimmed.substring(10)) : '';
      formatted = [part1, part2, part3].where((s) => s.isNotEmpty).join(' ');
    } else {
      final buffer = StringBuffer();
      for (int i = 0; i < trimmed.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(trimmed[i]);
      }
      formatted = buffer.toString();
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// TextInputFormatter for MM/YY expiry
class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 4) text = text.substring(0, 4);

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
