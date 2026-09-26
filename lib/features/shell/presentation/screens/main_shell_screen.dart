import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../advisor/presentation/screens/advisor_screen.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../calculator/presentation/screens/calculator_screen.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../providers/navigation_provider.dart';

class _Dest {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _Dest(this.icon, this.activeIcon, this.label);
}

const _destinations = [
  _Dest(AppIcons.navHome, AppIcons.navHomeActive, AppStrings.navHome),
  _Dest(AppIcons.navWallet, AppIcons.navWalletActive, AppStrings.navWallet),
  _Dest(AppIcons.navExplore, AppIcons.navExploreActive, AppStrings.navExplore),
  _Dest(AppIcons.navRewards, AppIcons.navRewardsActive, AppStrings.navRewards),
  _Dest(AppIcons.navProfile, AppIcons.navProfileActive, AppStrings.navProfile),
];

/// Adaptive shell: floating bottom bar on phones, navigation rail on
/// tablets / desktop.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static Widget _screenFor(int index) => switch (index) {
        0 => const AdvisorScreen(),
        1 => const WalletScreen(),
        2 => const CatalogScreen(),
        3 => const CalculatorScreen(),
        _ => const ProfileScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final size = context.windowSize;
    final useRail = size != WindowSize.compact;
    final extendedRail = size == WindowSize.expanded;

    void select(int i) {
      HapticsHelper.selection();
      nav.setIndex(i);
    }

    final stack = _FadeIndexedStack(
      index: nav.currentIndex,
      children: List.generate(
        _destinations.length,
        (i) => nav.isVisited(i) ? _screenFor(i) : const SizedBox.shrink(),
      ),
    );

    return PopScope(
      canPop: nav.currentIndex == NavigationProvider.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.setIndex(NavigationProvider.home);
      },
      child: Scaffold(
        extendBody: true,
        body: useRail
            ? Row(
                children: [
                  _Rail(index: nav.currentIndex, extended: extendedRail, onSelect: select),
                  VerticalDivider(width: 1, thickness: 1, color: context.colors.border),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final mq = MediaQuery.of(context);
                        return MediaQuery(
                          data: mq.copyWith(size: Size(box.maxWidth, mq.size.height)),
                          child: stack,
                        );
                      },
                    ),
                  ),
                ],
              )
            : stack,
        bottomNavigationBar: useRail ? null : _BottomBar(index: nav.currentIndex, onSelect: select),
      ),
    );
  }
}

/// IndexedStack that cross-fades between children while keeping state.
class _FadeIndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({required this.index, required this.children});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: TickerMode(
              enabled: i == index,
              child: AnimatedOpacity(
                opacity: i == index ? 1 : 0,
                duration: AppDimensions.fastAnim,
                curve: Curves.easeOut,
                child: children[i],
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _BottomBar({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRRect(
              borderRadius: AppDimensions.roundedXl,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: c.isDark ? 0.82 : 0.9),
                    borderRadius: AppDimensions.roundedXl,
                    border: Border.all(color: c.border),
                    boxShadow: [BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      for (var i = 0; i < _destinations.length; i++)
                        Expanded(
                          child: _BarItem(
                            dest: _destinations[i],
                            selected: i == index,
                            onTap: () => onSelect(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  const _BarItem({required this.dest, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accent : c.textTertiary;
    return Semantics(
      selected: selected,
      button: true,
      label: dest.label,
      child: PressableScale(
        onTap: onTap,
        haptic: false,
        pressedScale: 0.9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppDimensions.mediumAnim,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? c.tint(c.accent, c.isDark ? 0.16 : 0.12) : Colors.transparent,
                borderRadius: AppDimensions.roundedFull,
              ),
              child: AnimatedSwitcher(
                duration: AppDimensions.fastAnim,
                child: Icon(
                  selected ? dest.activeIcon : dest.icon,
                  key: ValueKey(selected),
                  size: 21,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppDimensions.fastAnim,
              style: context.text.labelSmall!
                  .copyWith(color: color, letterSpacing: 0.1, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
              child: Text(dest.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final int index;
  final bool extended;
  final ValueChanged<int> onSelect;

  const _Rail({required this.index, required this.extended, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NavigationRail(
      selectedIndex: index,
      extended: extended,
      minExtendedWidth: 200,
      onDestinationSelected: onSelect,
      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.p16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconHalo(icon: AppIcons.keyhole, size: 34, iconSize: 16, circle: true, color: c.accent),
            if (extended) ...[
              const SizedBox(width: 10),
              Text(AppStrings.appName, style: context.text.titleMedium),
            ],
          ],
        ),
      ),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon, size: 21),
            selectedIcon: Icon(d.activeIcon, size: 21),
            label: Text(d.label),
          ),
      ],
    );
  }
}
