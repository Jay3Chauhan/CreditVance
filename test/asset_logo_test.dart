import 'package:cardsage/core/constants/app_assets.dart';
import 'package:cardsage/core/widgets/network_logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Network Logo Asset and Widget Tests', () {
    test('AppAssets correctly resolves network names to PNG assets', () {
      expect(AppAssets.getNetworkLogoPng('Visa Infinite'), AppAssets.logoVisa);
      expect(AppAssets.getNetworkLogoPng('Mastercard World'), AppAssets.logoMastercard);
      expect(AppAssets.getNetworkLogoPng('American Express'), AppAssets.logoAmex);
      expect(AppAssets.getNetworkLogoPng('Amex Platinum'), AppAssets.logoAmex);
      expect(AppAssets.getNetworkLogoPng('RuPay / Visa'), AppAssets.logoVisa);
      expect(AppAssets.getNetworkLogoPng('RuPay Select'), AppAssets.logoRupay);
      expect(AppAssets.getNetworkLogoPng('Diners Club Black'), AppAssets.logoDinersClub);
      expect(AppAssets.getNetworkLogoPng('Discover it'), AppAssets.logoDiscover);
      expect(AppAssets.getNetworkLogoPng('Unknown Network'), isNull);
    });

    testWidgets('NetworkLogoWidget renders logo for known network', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NetworkLogoWidget(network: 'Visa Infinite'))),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('NetworkLogoWidget falls back to text for unknown network', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NetworkLogoWidget(network: 'Custom Bank Rail'))),
      );
      expect(find.text('CUSTOM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
