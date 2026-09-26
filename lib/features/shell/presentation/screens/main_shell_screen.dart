import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../advisor/presentation/screens/advisor_screen.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../calculator/presentation/screens/calculator_screen.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../providers/navigation_provider.dart';

/// Main Application Shell hosting the Luxury Bottom Navigation Bar and Feature Screens.
/// Strictly Zero setState: Uses Provider Consumers.
/// Custom luxury bottom nav replaces Material3 NavigationBar for premium fintech aesthetic.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _screens = [
    AdvisorScreen(),
    WalletScreen(),
    CatalogScreen(),
    CalculatorScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    _NavItemData(
      icon: AppIcons.navAdvisor,
      activeIcon: AppIcons.navAdvisorActive,
      label: AppStrings.navAdvisor,
    ),
    _NavItemData(
      icon: AppIcons.navWallet,
      activeIcon: AppIcons.navWalletActive,
      label: AppStrings.navWallet,
    ),
    _NavItemData(
      icon: AppIcons.navCatalog,
      activeIcon: AppIcons.navCatalogActive,
      label: AppStrings.navCatalog,
    ),
    _NavItemData(
      icon: AppIcons.navCalculator,
      activeIcon: AppIcons.navCalculatorActive,
      label: AppStrings.navCalculator,
    ),
    _NavItemData(
      icon: AppIcons.navProfile,
      activeIcon: AppIcons.navProfileActive,
      label: AppStrings.navProfile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, nav, _) {
        final currentIdx = nav.currentIndex;

        return Scaffold(
          // IndexedStack preserves state across tab switches
          body: IndexedStack(
            index: currentIdx,
            children: _screens,
          ),
          bottomNavigationBar: _LuxuryNavBar(
            currentIndex: currentIdx,
            items: _navItems,
            onTap: (idx) {
              HapticsHelper.selection();
              nav.setIndex(idx);
            },
          ),
        );
      },
    );
  }
}

/// Immutable nav item data.
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Custom luxury bottom navigation bar.
/// Features: animated gold underline indicator, icon scale spring, label weight transition.
/// Zero setState: all state driven by parent's currentIndex.
class _LuxuryNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  const _LuxuryNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isSelected = idx == currentIndex;

              return Expanded(
                child: _LuxuryNavItem(
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => onTap(idx),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Individual nav bar item with animated icon scale, label weight, and gold underline dot.
/// Zero setState: all animations driven by [isSelected] prop.
class _LuxuryNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LuxuryNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with scale animation
          AnimatedScale(
            scale: isSelected ? 1.18 : 1.0,
            duration: AppDimensions.springAnim,
            curve: Curves.elasticOut,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: isSelected ? AppColors.textSecondary : AppColors.gold,
                end: isSelected ? AppColors.gold : AppColors.textSecondary,
              ),
              duration: AppDimensions.fastAnim,
              builder: (ctx, color, _) => Icon(
                isSelected ? activeIcon : icon,
                color: color ?? (isSelected ? AppColors.gold : AppColors.textSecondary),
                size: 22,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Label with weight animation
          AnimatedDefaultTextStyle(
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? AppColors.gold : AppColors.textTertiary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: isSelected ? 10.5 : 10,
            ),
            duration: AppDimensions.fastAnim,
            child: Text(label),
          ),

          const SizedBox(height: 3),

          // Gold underline dot indicator
          AnimatedContainer(
            duration: AppDimensions.fastAnim,
            curve: Curves.easeOutCubic,
            width: isSelected ? 18 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: AppDimensions.roundedFull,
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x80DFB76C), // AppColors.gold with 0.5 opacity
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
          ),
        ],
      ),
    );
  }
}
