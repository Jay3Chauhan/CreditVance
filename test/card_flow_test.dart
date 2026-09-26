import 'dart:async';

import 'package:cardsage/core/network/api_result.dart';
import 'package:cardsage/core/storage/secure_vault_service.dart';
import 'package:cardsage/core/theme/app_theme.dart';
import 'package:cardsage/features/advisor/domain/entities/recommendation.dart';
import 'package:cardsage/features/advisor/domain/repositories/advisor_repository.dart';
import 'package:cardsage/features/advisor/domain/wallet_ranker.dart';
import 'package:cardsage/features/advisor/presentation/providers/advisor_provider.dart';
import 'package:cardsage/features/calculator/domain/entities/calculation_result.dart';
import 'package:cardsage/features/calculator/domain/reward_engine.dart';
import 'package:cardsage/features/catalog/domain/entities/bank.dart';
import 'package:cardsage/features/catalog/domain/entities/card_tab.dart';
import 'package:cardsage/features/catalog/domain/entities/catalog_card.dart';
import 'package:cardsage/features/catalog/domain/entities/category.dart';
import 'package:cardsage/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:cardsage/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:cardsage/features/catalog/presentation/widgets/catalog_card_tile.dart';
import 'package:cardsage/features/wallet/domain/entities/user_card.dart';
import 'package:cardsage/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:cardsage/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:cardsage/features/wallet/presentation/widgets/visual_credit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

CatalogCard _card(int id, {double fee = 0, double rate = 2}) => CatalogCard(
      id: id,
      name: 'Card $id',
      slug: 'card-$id',
      bankName: 'Bank',
      bankSlug: 'bank',
      network: 'Visa',
      cardType: 'Rewards',
      annualFee: fee,
      joiningFee: fee,
      rewardType: 'Points',
      baseReturnRate: rate,
    );

UserCard _userCard(int id, {double rate = 1, double? forex}) => UserCard(
      id: id,
      cardId: id,
      nickname: 'Card $id',
      last4Digits: '000$id',
      cardName: 'Card $id',
      bankName: 'Bank',
      network: 'Visa',
      baseReturnRate: rate,
      forexMarkup: forex,
    );

class FakeCatalogRepository implements CatalogRepository {
  final int total;
  final List<CatalogQuery> queries = [];
  final Map<String, Completer<void>> gates = {};

  FakeCatalogRepository({this.total = 45});

  @override
  Future<ApiResult<PagedResult<CatalogCard>>> getCards({
    CatalogQuery query = const CatalogQuery(),
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    queries.add(query);
    final gate = gates[query.search ?? ''];
    if (gate != null) await gate.future;
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, total);
    final items = [for (var i = start; i < end; i++) _card(i + 1)];
    return ApiSuccess(PagedResult(items: items, page: page, total: total, hasNext: end < total));
  }

  @override
  Future<ApiResult<CatalogCard>> getCardBySlug(String slug) async => ApiSuccess(_card(1));

  @override
  Future<ApiResult<CardTab>> getCardTab(String slug, String tabName) async => ApiSuccess(CardTab(name: tabName));

  @override
  Future<ApiResult<List<Bank>>> getBanks({bool forceRefresh = false}) async => const ApiSuccess([]);

  @override
  Future<ApiResult<List<SpendCategory>>> getCategories({bool forceRefresh = false}) async => const ApiSuccess([]);

  @override
  Future<void> clearCache() async {}
}

class FakeWalletRepository implements WalletRepository {
  List<UserCard> cards;
  List<int>? savedOrder;

  FakeWalletRepository(this.cards);

  @override
  Future<ApiResult<List<UserCard>>> getUserCards({bool forceRefresh = false}) async => ApiSuccess([...cards]);

  @override
  Future<ApiResult<UserCard>> addUserCard({
    required CatalogCard card,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  }) async {
    final c = UserCard(
      id: 100 + cards.length,
      cardId: card.id,
      nickname: nickname,
      last4Digits: last4Digits,
      cardName: card.name,
      bankName: card.bankName,
      network: card.network,
      hasVaultDetails: fullCardNumber != null,
    );
    cards.add(c);
    return ApiSuccess(c);
  }

  @override
  Future<ApiResult<UserCard>> updateUserCard(UserCard card, {String? nickname, int? billingCycleDay}) async =>
      ApiSuccess(card.copyWith(nickname: nickname, billingCycleDay: billingCycleDay));

  @override
  Future<ApiResult<bool>> deleteUserCard(int userCardId) async {
    cards.removeWhere((c) => c.id == userCardId);
    return const ApiSuccess(true);
  }

  @override
  Future<void> saveOrder(List<int> orderedIds) async => savedOrder = orderedIds;

  @override
  Future<List<UserCard>> loadSampleCards() async => const [];

  @override
  Future<VaultStatus> copyCardNumber(int userCardId, {required Duration clearAfter}) async => VaultStatus.success;

  @override
  Future<VaultStatus> copyField(int userCardId, String field, {required Duration clearAfter}) async =>
      VaultStatus.success;

  @override
  Future<(VaultStatus, VaultSecrets?)> readSecrets(int userCardId) async =>
      (VaultStatus.success, const VaultSecrets(pan: '4111111111111111', cvv: '123', expiry: '12/29'));

  @override
  Future<void> clearLocalWallet() async => cards = [];
}

class FakeAdvisorRepository implements AdvisorRepository {
  @override
  Future<ApiResult<AdvisorRecommendation>> getRecommendation({
    required String categorySlug,
    required double spendAmount,
    String? merchantName,
    bool isInternational = false,
  }) async {
    return ApiSuccess(AdvisorRecommendation(
      categorySlug: categorySlug,
      spendAmount: spendAmount,
      isInternational: isInternational,
      marketBest: RecommendationOption(
        cardId: 266,
        cardName: 'Market best',
        bankName: 'HDFC',
        returnPercentage: 10,
        estimatedValue: spendAmount * 0.1,
        rewardType: 'Points',
        reason: '',
      ),
      insights: const ["You haven't added any cards to your wallet yet."],
    ));
  }
}

void main() {
  group('CatalogProvider pagination', () {
    test('loads first page then appends pages until has_next is false', () async {
      final provider = CatalogProvider(FakeCatalogRepository(total: 45));
      await provider.init();
      expect(provider.cards.length, 20);
      expect(provider.total, 45);
      expect(provider.hasNext, isTrue);

      await provider.loadMore();
      expect(provider.cards.length, 40);
      await provider.loadMore();
      expect(provider.cards.length, 45);
      expect(provider.hasNext, isFalse);

      await provider.loadMore();
      expect(provider.cards.length, 45);
    });

    test('ignores stale responses from superseded searches', () async {
      final repo = FakeCatalogRepository(total: 5);
      final provider = CatalogProvider(repo);
      await provider.init();

      final slow = Completer<void>();
      repo.gates['slow'] = slow;
      provider.setSearchQuery('slow');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      provider.setSearchQuery('fast');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(provider.query.search, 'fast');
      slow.complete();
      await Future<void>.delayed(Duration.zero);
      expect(provider.query.search, 'fast');
      expect(provider.state.isLoaded, isTrue);
    });

    test('compare tray is capped', () async {
      final provider = CatalogProvider(FakeCatalogRepository());
      expect(provider.toggleCompare(_card(1)), isTrue);
      expect(provider.toggleCompare(_card(2)), isTrue);
      expect(provider.toggleCompare(_card(3)), isTrue);
      expect(provider.toggleCompare(_card(4)), isFalse);
      expect(provider.toggleCompare(_card(1)), isTrue);
      expect(provider.compareList.length, 2);
    });
  });

  group('WalletProvider', () {
    test('reorder keeps focus on the same card and persists order', () async {
      final repo = FakeWalletRepository([_userCard(1), _userCard(2), _userCard(3)]);
      final wallet = WalletProvider(repo);
      await wallet.loadCards();
      wallet.setFocusedIndex(0);

      wallet.reorder(0, 3);
      expect(wallet.cards.map((c) => c.id), [2, 3, 1]);
      expect(wallet.focusedCard?.id, 1);
      expect(repo.savedOrder, [2, 3, 1]);
    });

    test('reveal window counts down and hides secrets', () async {
      final wallet = WalletProvider(FakeWalletRepository([_userCard(1)]))..revealDuration = const Duration(seconds: 2);
      await wallet.loadCards();
      await wallet.toggleReveal(1);
      expect(wallet.isRevealed(1), isTrue);
      expect(wallet.revealRemaining.value, 2);
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(wallet.isRevealed(1), isFalse);
      wallet.dispose();
    });

    test('delete removes the card and updates state', () async {
      final wallet = WalletProvider(FakeWalletRepository([_userCard(1)]));
      await wallet.loadCards();
      await wallet.deleteCard(1);
      expect(wallet.cards, isEmpty);
      expect(wallet.state.isEmpty, isTrue);
    });
  });

  group('Ranking & rewards engines', () {
    test('international ranking penalises forex markup', () {
      final ranked = WalletRanker.rank(
        [_userCard(1, rate: 3, forex: 3.5), _userCard(2, rate: 2, forex: 0)],
        spend: 10000,
        isInternational: true,
      );
      expect(ranked.first.userCardId, 2);
    });

    test('guest advisor uses on-device ranking and keeps the market benchmark', () async {
      final advisor = AdvisorProvider(FakeAdvisorRepository());
      advisor.updateWallet([_userCard(1, rate: 1), _userCard(2, rate: 5)], isGuest: true);
      await advisor.init();
      final rec = advisor.recommendation!;
      expect(rec.source, RecommendationSource.onDevice);
      expect(rec.topCard?.userCardId, 2);
      expect(rec.marketBest, isNotNull);
      expect(rec.missedValue, greaterThan(0));
      expect(rec.insights, isEmpty);
    });

    test('reward engine applies fee waiver', () {
      const subject = RewardSubject(
        cardId: 1,
        name: 'X',
        bankName: 'B',
        baseRate: 2,
        annualFee: 1000,
        feeWaiverSpend: 100000,
      );
      final low = RewardEngine.calculate(subject, {SpendBucket.other: 1000});
      expect(low.feeWaived, isFalse);
      expect(low.netBenefit, 12000 * 0.02 - 1000);

      final high = RewardEngine.calculate(subject, {SpendBucket.other: 10000});
      expect(high.feeWaived, isTrue);
      expect(high.annualFee, 0);
    });
  });

  group('Widgets', () {
    testWidgets('VisualCreditCard renders revealed details without overflow and flips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: VisualCreditCard(
                  data: CardFaceData(
                    bankName: 'American Express Banking Corporation',
                    cardName: 'Amex Platinum Charge Credit Card With A Very Long Name',
                    network: 'American Express',
                    last4: '2345',
                    nickname: 'My extremely long travel card nickname',
                    fullNumber: '371212345612345',
                    expiry: '12/29',
                    cvv: '7777',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('3712 123456 12345'), findsOneWidget);
      expect(find.text('12/29'), findsOneWidget);
    });

    testWidgets('CatalogCardTile shows name, return and fee', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(FakeCatalogRepository()),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: CatalogCardTile(card: _card(7, fee: 0, rate: 2.5))),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Card 7'), findsOneWidget);
      expect(find.text('2.5%'), findsOneWidget);
      expect(find.text('Lifetime free'), findsOneWidget);
    });
  });
}
