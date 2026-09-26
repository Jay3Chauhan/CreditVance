import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// Biometric app lock + privacy cover for the app switcher.
///
/// Locks on launch and after [relockAfter] in the background when app lock
/// is enabled. Revealed card secrets are always hidden on background.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  static const Duration relockAfter = Duration(seconds: 15);

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

/// Owns the lifecycle observer; UI state lives in ValueNotifiers.
class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final ValueNotifier<bool> _locked = ValueNotifier(false);
  final ValueNotifier<bool> _covered = ValueNotifier(false);
  DateTime? _backgroundedAt;
  bool _authenticating = false;

  SettingsProvider get _settings => context.read<SettingsProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (context.read<SettingsProvider>().settings.appLockEnabled) {
      _locked.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locked.dispose();
    _covered.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;
    switch (state) {
      case AppLifecycleState.inactive:
        if (_settings.settings.blockScreenshots) _covered.value = true;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
        _covered.value = _settings.settings.blockScreenshots;
        context.read<WalletProvider>().hideSecrets();
      case AppLifecycleState.resumed:
        _covered.value = false;
        final away = _backgroundedAt == null ? Duration.zero : DateTime.now().difference(_backgroundedAt!);
        _backgroundedAt = null;
        if (_settings.settings.appLockEnabled && away >= AppLockGate.relockAfter) {
          _locked.value = true;
          _unlock();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    final status = await context.read<SecureVaultService>().authenticate(reason: AppStrings.biometricUnlockReason);
    _authenticating = false;
    if (status.isSuccess || status == VaultStatus.notEnrolled) _locked.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<bool>(
          valueListenable: _locked,
          builder: (context, locked, _) => locked ? _LockedView(onUnlock: _unlock) : const SizedBox.shrink(),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _covered,
          builder: (context, covered, _) => covered ? const _PrivacyCover() : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _LockedView extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockedView({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Material(
        color: c.canvas,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.p32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                  child: const Icon(AppIcons.keyhole, size: 30, color: AppColors.black),
                )
                    .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1400.ms),
                const SizedBox(height: AppDimensions.p20),
                Text('${AppStrings.appName} is locked', style: context.text.headlineMedium),
                const SizedBox(height: AppDimensions.p6),
                Text('Unlock with your fingerprint or face', style: context.text.bodyMedium),
                const Spacer(flex: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: AppButton(label: 'Unlock', icon: AppIcons.fingerprint, onPressed: onUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(
          color: c.canvas.withValues(alpha: 0.85),
          child: Center(child: Icon(AppIcons.lockFill, size: 36, color: c.accent)),
        ),
      ),
    );
  }
}
