import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../advisor/presentation/screens/advisor_screen.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../calculator/presentation/screens/calculator_screen.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../providers/navigation_provider.dart';

/// Main Application Shell hosting the Luxury Bottom Navigation Bar and Feature Screens.
/// Strictly Zero setState: Uses Provider Consumers.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _screens = [
    AdvisorScreen(),
    WalletScreen(),
    CatalogScreen(),
    CalculatorScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, nav, _) {
        final currentIdx = nav.currentIndex;

        return Scaffold(
          body: IndexedStack(
            index: currentIdx,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfacePrimary,
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
              ),
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: currentIdx,
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.gold.withOpacity(0.18),
                elevation: 0,
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (idx) {
                  HapticsHelper.selection();
                  nav.setIndex(idx);
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(AppIcons.navAdvisor, color: AppColors.textSecondary),
                    selectedIcon: const Icon(AppIcons.navAdvisorActive, color: AppColors.gold),
                    label: AppStrings.navAdvisor,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.navWallet, color: AppColors.textSecondary),
                    selectedIcon: const Icon(AppIcons.navWalletActive, color: AppColors.gold),
                    label: AppStrings.navWallet,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.navCatalog, color: AppColors.textSecondary),
                    selectedIcon: const Icon(AppIcons.navCatalogActive, color: AppColors.gold),
                    label: AppStrings.navCatalog,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.navCalculator, color: AppColors.textSecondary),
                    selectedIcon: const Icon(AppIcons.navCalculatorActive, color: AppColors.gold),
                    label: AppStrings.navCalculator,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.navProfile, color: AppColors.textSecondary),
                    selectedIcon: const Icon(AppIcons.navProfileActive, color: AppColors.gold),
                    label: AppStrings.navProfile,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
