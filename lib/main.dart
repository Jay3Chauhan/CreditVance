import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'core/constants/app_strings.dart';
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
import 'features/catalog/data/repositories/catalog_repository_impl.dart';
import 'features/catalog/domain/repositories/catalog_repository.dart';
import 'features/catalog/presentation/providers/catalog_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/shell/presentation/providers/navigation_provider.dart';
import 'features/shell/presentation/screens/main_shell_screen.dart';
import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/presentation/providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final cache = LocalCacheService(prefs);
  final vault = SecureVaultService();
  final api = ApiClient(cacheService: cache);

  final CatalogRepository catalogRepo = CatalogRepositoryImpl(apiClient: api, cacheService: cache);
  final walletRepo = WalletRepositoryImpl(apiClient: api, vaultService: vault, cacheService: cache);

  final settings = SettingsProvider(cache);
  final auth = AuthProvider(AuthRepositoryImpl(apiClient: api, cacheService: cache))..restore();
  final wallet = WalletProvider(walletRepo);
  final catalog = CatalogProvider(catalogRepo)..init();
  final advisor = AdvisorProvider(AdvisorRepositoryImpl(apiClient: api));
  final calculator = CalculatorProvider();

  api.onUnauthorized = auth.handleSessionExpired;

  void applySettings() {
    wallet
      ..clipboardDuration = Duration(seconds: settings.settings.clipboardClearSeconds)
      ..revealDuration = Duration(seconds: settings.settings.revealSeconds);
  }

  var lastStatus = AuthStatus.unknown;
  void onAuthChanged() {
    final status = auth.status;
    if (status == lastStatus) return;
    lastStatus = status;
    if (auth.isAuthenticated) {
      wallet.loadCards();
      advisor.init();
    } else {
      wallet.reset();
    }
  }

  void onWalletChanged() {
    advisor.updateWallet(wallet.cards, isGuest: auth.isGuest);
    calculator.updateWallet(wallet.cards);
  }

  settings.addListener(applySettings);
  auth.addListener(onAuthChanged);
  wallet.addListener(onWalletChanged);
  applySettings();
  onAuthChanged();

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureVaultService>.value(value: vault),
        Provider<CatalogRepository>.value(value: catalogRepo),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: wallet),
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: advisor),
        ChangeNotifierProvider.value(value: calculator),
      ],
      child: const CreditVanceApp(),
    ),
  );
}

class CreditVanceApp extends StatelessWidget {
  const CreditVanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return ToastificationWrapper(
      child: MaterialApp(
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
        home: const _AuthGate(),
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
