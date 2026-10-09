import 'package:credvert/core/storage/local_cache_service.dart';
import 'package:credvert/core/theme/app_theme.dart';
import 'package:credvert/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:credvert/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:credvert/features/expenses/domain/entities/spend_analytics.dart';
import 'package:credvert/features/expenses/domain/entities/sms_tracking_status.dart';
import 'package:credvert/features/expenses/presentation/providers/expense_provider.dart';
import 'package:credvert/features/expenses/presentation/screens/sms_consent_screen.dart';
import 'package:credvert/features/expenses/presentation/screens/spend_insights_screen.dart';
import 'package:credvert/features/expenses/presentation/screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  final now = DateTime.now();

  Future<(ExpenseProvider, FakeSmsPlatform)> buildProvider(
    WidgetTester tester, {
    bool withData = true,
    bool supported = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final cache = LocalCacheService(await SharedPreferences.getInstance());
    final platform = FakeSmsPlatform(sampleInbox(now), supported: supported);
    final repo = ExpenseRepositoryImpl(
      platform: platform,
      local: ExpenseLocalDataSource(cache),
      remote: FakeExpenseRemote(cache),
    );
    if (withData) {
      await repo.saveConsent(SmsConsent(status: SmsConsentStatus.granted, decidedAt: now));
      await tester.runAsync(() => repo.scanInbox());
    }
    // Keep the provider from re-scanning in the fake-async zone.
    platform.granted = false;
    final provider = ExpenseProvider(repo, observeLifecycle: false, clock: () => now);
    await provider.init();
    provider.setPeriod(AnalyticsPeriod.last3Months);
    return (provider, platform);
  }

  Widget host(ExpenseProvider provider, Widget child) => ChangeNotifierProvider<ExpenseProvider>.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.darkTheme, home: child),
      );

  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Spend Insights renders analytics from parsed SMS without overflow', (tester) async {
    useTallPhone(tester);
    final (provider, _) = await buildProvider(tester);
    await tester.pumpWidget(host(provider, const SpendInsightsScreen()));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('NET CARD SPEND • 3 MONTHS'), findsOneWidget);
    expect(find.text('Upcoming bills'), findsOneWidget);
    expect(find.text('Where you spent'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Recent transactions'), 400, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spend Insights fits a compact 360dp phone', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (provider, _) = await buildProvider(tester);
    await tester.pumpWidget(host(provider, const SpendInsightsScreen()));
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Transactions screen filters by type', (tester) async {
    useTallPhone(tester);
    final (provider, _) = await buildProvider(tester);
    await tester.pumpWidget(
      host(
        provider,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => TransactionsScreen.open(context), child: const Text('open')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(provider.filteredTransactions.length, 4);
    await tester.tap(find.text('Refunds'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(provider.filteredTransactions.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Consent screen shows the prominent disclosure before any permission request', (tester) async {
    useTallPhone(tester);
    final (provider, _) = await buildProvider(tester, withData: false);
    await tester.pumpWidget(
      host(
        provider,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => SmsConsentScreen.open(context), child: const Text('open')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('What we read'), findsOneWidget);
    expect(find.text('What stays on your phone'), findsOneWidget);
    expect(provider.consent.status, SmsConsentStatus.notAsked);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unsupported platform (iOS) shows the paste/manual fallback notice', (tester) async {
    useTallPhone(tester);
    final (provider, _) = await buildProvider(tester, withData: false, supported: false);
    await tester.pumpWidget(host(provider, const SpendInsightsScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('SMS reading is Android-only'), findsOneWidget);
    expect(find.text('Add a spend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
