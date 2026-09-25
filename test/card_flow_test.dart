import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cardsage/core/theme/app_theme.dart';
import 'package:cardsage/core/network/api_result.dart';
import 'package:cardsage/features/catalog/domain/entities/bank.dart';
import 'package:cardsage/features/catalog/domain/entities/category.dart';
import 'package:cardsage/features/catalog/domain/entities/catalog_card.dart';
import 'package:cardsage/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:cardsage/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:cardsage/features/catalog/presentation/widgets/catalog_card_tile.dart';
import 'package:cardsage/features/wallet/domain/entities/user_card.dart';
import 'package:cardsage/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:cardsage/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:cardsage/features/wallet/presentation/screens/add_card_screen.dart';
import 'package:cardsage/features/wallet/presentation/widgets/visual_credit_card.dart';

class MockCatalogRepository implements CatalogRepository {
  @override
  Future<ApiResult<List<CatalogCard>>> getCards({
    String? search,
    String? bankSlug,
    String? network,
    String? feeType,
    bool? isPopular,
    String? sortBy,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async =>
      const ApiSuccess([]);

  @override
  Future<ApiResult<CatalogCard>> getCardBySlug(String slug) async =>
      throw UnimplementedError();

  @override
  Future<ApiResult<List<Bank>>> getBanks({bool forceRefresh = false}) async =>
      const ApiSuccess([]);

  @override
  Future<ApiResult<List<SpendCategory>>> getCategories({bool forceRefresh = false}) async =>
      const ApiSuccess([]);
}

class MockWalletRepository implements WalletRepository {
  final List<UserCard> _cards = [];

  @override
  Future<ApiResult<List<UserCard>>> getUserCards({bool forceRefresh = false}) async =>
      ApiSuccess(_cards);

  @override
  Future<ApiResult<UserCard>> addUserCard({
    required int cardId,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  }) async {
    final newCard = UserCard(
      id: 999,
      cardId: cardId,
      nickname: nickname,
      last4Digits: last4Digits,
      cardName: 'Amex Platinum Charge Credit Card',
      bankName: 'Amex',
      network: 'American Express',
      hasVaultDetails: fullCardNumber != null,
    );
    _cards.add(newCard);
    return ApiSuccess(newCard);
  }

  @override
  Future<ApiResult<UserCard>> updateUserCard(int userCardId, {String? nickname, String? last4Digits}) async =>
      throw UnimplementedError();

  @override
  Future<ApiResult<bool>> deleteUserCard(int userCardId) async => const ApiSuccess(true);

  @override
  Future<bool> copyCardNumberWithBiometrics(int userCardId) async => true;

  @override
  Future<Map<String, String>?> getCardDetailsWithBiometrics(int userCardId) async => null;
}

void main() {
  const testCard = CatalogCard(
    id: 195,
    name: 'Amex Platinum Charge Credit Card',
    slug: 'amex-platinum-charge',
    bankName: 'Amex',
    bankSlug: 'amex',
    network: 'American Express',
    cardType: 'Super Premium',
    annualFee: 66000.0,
    joiningFee: 66000.0,
    rewardType: 'Reward Points',
    baseReturnRate: 2.5,
    imageUrl: 'https://d3dx7t8uh9asmu.cloudfront.net/Mapped/AMEX.webp',
    bankLogoUrl: 'https://d3dx7t8uh9asmu.cloudfront.net/bank_square/AMEX.png',
    keyPerks: ['24/7 dedicated luxury concierge assistance', 'Dining discounts & Swiggy/Zomato benefits'],
  );

  group('VisualCreditCard Layout and Overflow Protection Tests', () {
    testWidgets('VisualCreditCard renders long name and credentials with zero RenderFlex overflow', (tester) async {
      final userCard = UserCard(
        id: 1,
        cardId: testCard.id,
        nickname: testCard.name,
        last4Digits: '8888',
        cardName: testCard.name,
        bankName: testCard.bankName,
        network: testCard.network,
        imageUrl: testCard.imageUrl,
        bankLogoUrl: testCard.bankLogoUrl,
        hasVaultDetails: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: VisualCreditCard(
                  card: userCard,
                  isUnmasked: true,
                  unmaskedPan: '3712 123456 12345',
                  unmaskedExpiry: '12/29',
                  unmaskedCvv: '7777',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow exceptions occurred
      expect(tester.takeException(), isNull);
      expect(find.text('AMEX'), findsOneWidget);
      expect(find.text('Amex Platinum Charge Credit Card'), findsWidgets);
      expect(find.text('12/29'), findsOneWidget);
      expect(find.text('7777'), findsOneWidget);
      expect(find.text('American Express'), findsOneWidget);
    });
  });

  group('AddCardScreen Preselected Flow and Validation Tests', () {
    testWidgets('AddCardScreen with preselectedCard locks card model and hides dropdown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockWallet = MockWalletRepository();
      final mockCatalog = MockCatalogRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => WalletProvider(mockWallet)),
            ChangeNotifierProvider(create: (_) => CatalogProvider(mockCatalog)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AddCardScreen(preselectedCard: testCard),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify header and locked summary
      expect(find.text('Add Amex Card'), findsOneWidget);
      expect(find.text('Selected Card Model'), findsOneWidget);
      expect(find.text('Select Card Model'), findsNothing); // Dropdown title should NOT be present!
      expect(find.byType(DropdownButton<int>), findsNothing); // No dropdown!

      // 2. Verify prefilled card details in live card and nickname
      expect(find.text('My Amex Platinum Charge Credit Card'), findsWidgets);

      // 3. Test Validation: Tap Save without entering PAN
      await tester.tap(find.text('Securely Save Card'));
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.text('Please enter at least 4 digits.'), findsOneWidget);

      // 4. Enter valid 4 digits
      await tester.enterText(find.widgetWithText(TextField, '4532 0000 0000 0000'), '8888');
      await tester.pumpAndSettle();

      // Error message cleared
      expect(find.text('Please enter at least 4 digits.'), findsNothing);
    });

    testWidgets('CatalogCardTile renders bank logo and card details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CatalogCardTile(card: testCard),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AMEX'), findsOneWidget);
      expect(find.text('Amex Platinum Charge Credit Card'), findsOneWidget);
      expect(find.text('2.5% Return'), findsOneWidget);
      expect(find.text('American Express'), findsOneWidget);
    });
  });
}
