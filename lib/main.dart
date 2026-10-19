import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'core/constants/app_strings.dart';
import 'core/firebase/analytics_service.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/messaging_service.dart';
import 'core/navigation/root_navigator.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_cache_service.dart';
import 'core/storage/secure_vault_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/context_ext.dart';
import 'features/advisor/data/repositories/advisor_repository_impl.dart';
import 'features/advisor/presentation/providers/advisor_provider.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/widgets/app_lock_gate.dart';
import 'features/calculator/presentation/providers/calculator_provider.dart';
import 'features/content/data/content_repository.dart';
import 'features/content/presentation/providers/home_provider.dart';
import 'features/content/presentation/providers/shortlist_provider.dart';
import 'features/catalog/data/repositories/catalog_repository_impl.dart';
import 'features/catalog/domain/repositories/catalog_repository.dart';
import 'features/catalog/presentation/providers/catalog_provider.dart';
import 'features/expenses/data/datasources/expense_local_datasource.dart';
import 'features/expenses/data/datasources/expense_remote_datasource.dart';
import 'features/expenses/data/datasources/sms_platform_datasource.dart';
import 'features/expenses/data/repositories/expense_repository_impl.dart';
import 'features/expenses/presentation/providers/expense_provider.dart';
import 'features/remote_config/data/remote_config_source.dart';
import 'features/remote_config/presentation/app_status_gate.dart';
import 'features/remote_config/presentation/remote_config_controller.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/shell/presentation/providers/navigation_provider.dart';
import 'features/shell/presentation/screens/main_shell_screen.dart';
import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/presentation/providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.start();

  final prefs = await SharedPreferences.getInstance();
  final cache = LocalCacheService(prefs);
  final vault = SecureVaultService();
  final api = ApiClient(cacheService: cache);
  MessagingService.bindApiClient(api);

  final CatalogRepository catalogRepo = CatalogRepositoryImpl(apiClient: api, cacheService: cache);
  final walletRepo = WalletRepositoryImpl(apiClient: api, vaultService: vault, cacheService: cache);
  final expenseRepo = ExpenseRepositoryImpl(
    platform: const MethodChannelSmsDataSource(),
    local: ExpenseLocalDataSource(cache),
    remote: ExpenseRemoteDataSource(api),
  );

  final settings = SettingsProvider(cache);
  RemoteConfigSource remoteSource = StaticRemoteConfigSource();
  if (firebaseReady) {
    try {
      remoteSource = await FirebaseRemoteConfigSource.create();
    } catch (error, stack) {
      debugPrint('Remote Config setup failed: $error\n$stack');
    }
  }
  final remoteConfig = RemoteConfigController(cache: cache, source: remoteSource);
  unawaited(remoteConfig.start());

  final auth = AuthProvider(AuthRepositoryImpl(apiClient: api, cacheService: cache))..restore();
  final wallet = WalletProvider(walletRepo);
  final catalog = CatalogProvider(catalogRepo)..init();
  final advisor = AdvisorProvider(AdvisorRepositoryImpl(apiClient: api));
  final calculator = CalculatorProvider();
  final expenses = ExpenseProvider(expenseRepo)..init();
  final content = ContentRepository(api);
  final home = HomeProvider(content);
  final shortlist = ShortlistProvider(content);
  final navigation = NavigationProvider();

  api.onUnauthorized = auth.handleSessionExpired;

  void applySettings() {
    wallet
      ..clipboardDuration = Duration(seconds: settings.settings.clipboardClearSeconds)
      ..revealDuration = Duration(seconds: settings.settings.revealSeconds);
    unawaited(AnalyticsService.applyCollection(settings.settings.diagnosticsEnabled));
  }

  void onNavigationChanged() {
    unawaited(AnalyticsService.screen(_screenName(navigation.currentIndex)));
  }

  var lastStatus = AuthStatus.unknown;
  void onAuthChanged() {
    final status = auth.status;
    final previous = lastStatus;
    if (status == lastStatus) return;
    lastStatus = status;
    final authState = switch (status) {
      AuthStatus.signedIn => 'signed_in',
      AuthStatus.guest => 'guest',
      AuthStatus.signedOut => 'signed_out',
      AuthStatus.unknown => 'unknown',
    };
    final userId = auth.isSignedIn && (auth.user?.id ?? 0) != 0 ? '${auth.user!.id}' : null;
    unawaited(AnalyticsService.setAuth(userId: userId, state: authState));

    if (auth.isAuthenticated) {
      wallet.loadCards();
      advisor.init();
      home
        ..load()
        ..loadBanners('catalog_top');
      if (auth.isSignedIn) {
        shortlist.refresh();
        home.loadBanners('wallet', audience: 'member', force: true);
        unawaited(MessagingService.syncDeviceToken(api));
      } else {
        shortlist.clear();
        home.clearMemberContent();
      }
    } else {
      wallet.reset();
      shortlist.clear();
      home.clearMemberContent();
      unawaited(MessagingService.unregisterDeviceToken(api));
      if (previous == AuthStatus.signedIn || previous == AuthStatus.guest) {
        unawaited(expenses.clearOnSignOut());
      }
    }
  }

  var walletSignature = '';
  void onWalletChanged() {
    advisor.updateWallet(wallet.cards, isGuest: auth.isGuest);
    calculator.updateWallet(wallet.cards);
    final signature = wallet.cards.map((c) => '${c.id}:${c.billingCycleDay}:${c.dueDay}').join(',');
    if (signature != walletSignature) {
      walletSignature = signature;
      if (auth.isSignedIn && wallet.cards.isNotEmpty) home.loadWalletInsights();
    }
    expenses.updateCards(wallet.cards);
  }

  settings.addListener(applySettings);
  auth.addListener(onAuthChanged);
  wallet.addListener(onWalletChanged);
  navigation.addListener(onNavigationChanged);
  applySettings();
  onAuthChanged();
  onNavigationChanged();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<SecureVaultService>.value(value: vault),
        Provider<CatalogRepository>.value(value: catalogRepo),
        Provider<ContentRepository>.value(value: content),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: remoteConfig),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: navigation),
        ChangeNotifierProvider.value(value: wallet),
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: advisor),
        ChangeNotifierProvider.value(value: calculator),
        ChangeNotifierProvider.value(value: home),
        ChangeNotifierProvider.value(value: shortlist),
        ChangeNotifierProvider.value(value: expenses),
      ],
      child: const CredvertApp(),
    ),
  );
}

String _screenName(int index) => switch (index) {
      NavigationProvider.home => 'home',
      NavigationProvider.wallet => 'wallet',
      NavigationProvider.spends => 'spends',
      NavigationProvider.explore => 'explore',
      NavigationProvider.rewards => 'rewards',
      _ => 'account',
    };

class CredvertApp extends StatelessWidget {
  const CredvertApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return ToastificationWrapper(
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        themeAnimationDuration: const Duration(milliseconds: 280),
        builder: (context, child) => AnnotatedRegion(
          value: AppTheme.overlayFor(Theme.of(context).brightness),
          child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
        ),
        home: const AppStatusGate(child: _AuthGate()),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    final Widget child = switch (status) {
      AuthStatus.unknown => ColoredBox(color: context.colors.canvas),
      AuthStatus.signedOut => const AuthScreen(),
      AuthStatus.guest || AuthStatus.signedIn => const AppLockGate(child: MainShellScreen()),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      child: KeyedSubtree(key: ValueKey(status == AuthStatus.signedOut), child: child),
    );
  }
}
