import 'package:flutter_test/flutter_test.dart';
import 'package:cardsage/core/utils/currency_formatter.dart';
import 'package:cardsage/core/utils/card_formatter.dart';
import 'package:cardsage/core/data/mock_seed_data.dart';

void main() {
  group('CardSage Core Utilities Smoke Tests', () {
    test('CurrencyFormatter formats INR correctly', () {
      expect(CurrencyFormatter.format(5000), '₹5,000');
      expect(CurrencyFormatter.format(150000), '₹1,50,000');
      expect(CurrencyFormatter.formatPercentage(5.0), '5%');
      expect(CurrencyFormatter.formatPercentage(3.3), '3.3%');
      expect(CurrencyFormatter.compact(950), '₹950');
      expect(CurrencyFormatter.compact(12500), '₹12.5K');
      expect(CurrencyFormatter.compact(320000), '₹3.2L');
      expect(CurrencyFormatter.compact(11000000), '₹1.1Cr');
    });

    test('CardFormatter masks and formats PAN correctly', () {
      expect(CardFormatter.maskCardNumber('4321'), '•••• •••• •••• 4321');
      expect(CardFormatter.formatFullPan('4532981234569012'), '4532 9812 3456 9012');
      expect(CardFormatter.detectNetwork('4532000000000000'), 'Visa');
      expect(CardFormatter.detectNetwork('5412000000000000'), 'Mastercard');
      expect(CardFormatter.detectNetwork('371200000000000'), 'American Express');
      expect(CardFormatter.detectNetwork('6012000000000000'), 'RuPay');

      // Validation
      expect(CardFormatter.validateCardNumber('4532015000000000'), isFalse);
      expect(CardFormatter.validateExpiry('12/29'), isTrue);
      expect(CardFormatter.validateExpiry('01/20'), isFalse); // past year
      expect(CardFormatter.validateExpiry('14/28'), isFalse); // invalid month
      expect(CardFormatter.validateCvv('123'), isTrue);
      expect(CardFormatter.validateCvv('1234', network: 'American Express'), isTrue);
      expect(CardFormatter.validateCvv('12', network: 'Visa'), isFalse);
    });

    test('MockSeedData contains rich realistic credit cards and banks', () {
      expect(MockSeedData.sampleCards.length, greaterThanOrEqualTo(5));
      expect(MockSeedData.banks.length, greaterThanOrEqualTo(10));
      expect(MockSeedData.categories.length, greaterThanOrEqualTo(10));

      final infinia = MockSeedData.sampleCards.firstWhere((c) => c.slug == 'hdfc-infinia-metal');
      expect(infinia.name, contains('Infinia'));
      expect(infinia.tabs.containsKey('earn-categories'), isTrue);
    });
  });
}
