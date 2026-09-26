import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_cache_service.dart';
import 'core/storage/secure_vault_service.dart';
import 'core/theme/app_theme.dart';

import 'features/advisor/data/repositories/advisor_repository_impl.dart';
import 'features/advisor/presentation/providers/advisor_provider.dart';

import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

import 'features/calculator/data/repositories/calculator_repository_impl.dart';
import 'features/calculator/presentation/providers/calculator_provider.dart';

import 'features/catalog/data/repositories/catalog_repository_impl.dart';
import 'features/catalog/presentation/providers/catalog_provider.dart';

import 'features/shell/presentation/providers/navigation_provider.dart';
import 'features/shell/presentation/screens/main_shell_screen.dart';

import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/presentation/providers/wallet_provider.dart';
import 'features/wallet/presentation/screens/add_card_screen.dart';
import 'features/catalog/domain/entities/catalog_card.dart';
import 'features/catalog/presentation/screens/card_detail_screen.dart';

const sampleCard = CatalogCard(
  id: 101,
  name: 'Amex Platinum Charge Credit Card',
  slug: 'amex-platinum-charge',
  bankName: 'American Express',
  bankSlug: 'amex',
  network: 'American Express',
  cardType: 'Super-Premium',
  annualFee: 66000,
  joiningFee: 66000,
  rewardType: 'Reward Points',
  baseReturnRate: 2.5,
  imageUrl: 'https://d3dx7t8uh9asmu.cloudfront.net/Mapped/AMEX.webp',
  bankLogoUrl: 'https://d3dx7t8uh9asmu.cloudfront.net/bank_square/AMEX.png',
  keyPerks: [
    'Unlimited domestic & international airport lounge visits',
    'Taj, SeleQtions & Vivanta hotel membership upgrade',
    '1 Membership Reward point per ₹50 spent',
  ],
);

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (dark status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Initialize Local Cache & Secure Hardware Vault
  final prefs = await SharedPreferences.getInstance();
  final cacheService = LocalCacheService(prefs);
  final vaultService = SecureVaultService();

  // Initialize Network Client
  final apiClient = ApiClient(cacheService: cacheService);

  // Initialize Repositories
  final catalogRepo = CatalogRepositoryImpl(apiClient: apiClient, cacheService: cacheService);
  final walletRepo = WalletRepositoryImpl(apiClient: apiClient, vaultService: vaultService);
  final advisorRepo = AdvisorRepositoryImpl(apiClient: apiClient);
  final calculatorRepo = CalculatorRepositoryImpl(apiClient: apiClient);
  final authRepo = AuthRepositoryImpl(
    apiClient: apiClient,
    cacheService: cacheService,
    vaultService: vaultService,
  );

  int initialTab = 0;
  Widget? customHome;

  const routeOverride = String.fromEnvironment('ROUTE');
  final debugScreen =
      routeOverride.isNotEmpty ? routeOverride : prefs.getString('debug_screen');
  if (debugScreen == 'card-detail' || args.contains('card-detail')) {
    customHome = const CardDetailScreen(card: sampleCard);
  } else if (debugScreen == 'add-card' || args.contains('add-card')) {
    customHome = const AddCardScreen(preselectedCard: sampleCard);
  } else if (debugScreen == 'explore' || args.contains('explore')) {
    initialTab = 2;
  } else if (debugScreen != null && int.tryParse(debugScreen) != null) {
    initialTab = int.parse(debugScreen);
  } else if (args.isNotEmpty && int.tryParse(args.first) != null) {
    initialTab = int.parse(args.first);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider(initialIndex: initialTab)),
        ChangeNotifierProvider(create: (_) => CatalogProvider(catalogRepo)..init()),
        ChangeNotifierProvider(create: (_) => WalletProvider(walletRepo)..init()),
        ChangeNotifierProvider(create: (_) => AdvisorProvider(advisorRepo)..init()),
        ChangeNotifierProvider(create: (_) => CalculatorProvider(calculatorRepo)..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)..init()),
      ],
      child: CardSageApp(home: customHome),
    ),
  );
}

/// Root Application Widget.
/// Zero setState: Extends StatelessWidget.
class CardSageApp extends StatelessWidget {
  final Widget? home;
  const CardSageApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: home ?? const MainShellScreen(),
      ),
    );
  }
}
