import 'package:flutter_test/flutter_test.dart';
import 'package:cardsage/features/catalog/data/models/catalog_card_model.dart';

void main() {
  group('CatalogCardModel JSON Parsing Tests', () {
    test('Correctly parses FastAPI card payload with title and display_name', () {
      final json = {
        'id': 477,
        'slug': 'hsbc-priv',
        'title': 'HSBC Privé Credit Card',
        'display_name': 'Privé',
        'bank_name': 'HSBC',
        'bank_slug': 'hsbc',
        'network_type': 'MASTERCARD',
        'joining_fee': 0.0,
        'renewal_fee': 0.0,
        'return_min_percent': 5.0,
        'return_max_percent': 60.0,
        'lounge_types': ['DOMESTIC_LOUNGE', 'INTERNATIONAL_LOUNGE'],
        'benefit_types': ['DINING_ORDER_IN', 'SHOPPING'],
        'is_popular': true,
      };

      final card = CatalogCardModel.fromJson(json);

      expect(card.id, 477);
      expect(card.name, 'HSBC Privé Credit Card');
      expect(card.bankName, 'HSBC');
      expect(card.network, 'Mastercard');
      expect(card.annualFee, 0.0);
      expect(card.isLifetimeFree, true);
      expect(card.baseReturnRate, 5.0);
      expect(card.isPopular, true);
      expect(card.keyPerks.length, greaterThanOrEqualTo(2));
      expect(card.tabs.containsKey('lounge-access'), isTrue);
    });

    test('Correctly falls back to display_name or Credit Card when title is empty', () {
      final json = {
        'id': 10,
        'slug': 'axis-card',
        'title': '',
        'display_name': 'Magnus',
        'bank_name': 'Axis Bank',
        'network_type': 'VISA',
        'renewal_fee': 10000.0,
      };

      final card = CatalogCardModel.fromJson(json);
      expect(card.name, 'Magnus');
      expect(card.annualFee, 10000.0);
      expect(card.network, 'Visa');
    });

    test('Ensures card name is never empty even with corrupted json', () {
      final json = {
        'id': 99,
        'name': '',
        'title': '',
        'display_name': '',
      };

      final card = CatalogCardModel.fromJson(json);
      expect(card.name, 'Credit Card');
      expect(card.name.isNotEmpty, true);
    });
  });
}
