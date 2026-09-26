import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    final isGuest = context.select<AuthProvider, bool>((a) => a.isGuest);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const _ProfileHeader(),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isGuest) const _GuestUpsell(),
                const _AppearanceSection(),
                const _SecuritySection(),
                const _DataSection(),
                const _AboutSection(),
                const SizedBox(height: AppDimensions.p24),
                const _SignOutButton(),
                const SizedBox(height: AppDimensions.p16),
                Center(
                  child: Text('${AppStrings.appName} v${AppStrings.appVersion}', style: context.text.labelSmall),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: context.navClearance)),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final user = auth.user;
    final name = auth.isGuest ? 'Guest' : (user?.fullName.isNotEmpty ?? false ? user!.fullName : 'Your account');
    final subtitle = auth.isGuest ? 'Everything stays on this device' : (user?.email ?? '');
    final secured = wallet.cards.where((c) => c.hasVaultDetails).length;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 250,
      title: Text(AppStrings.navProfile, style: context.text.titleMedium),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.tint(c.accent, c.isDark ? 0.16 : 0.14), c.canvas],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.gutter(), 52, context.gutter(), 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: auth.isGuest
                            ? const Icon(AppIcons.user, color: AppColors.black, size: 24)
                            : Text(user?.initials ?? '', style: AppTypography.numeric(20, color: AppColors.black)),
                      ).animate().scale(duration: AppDimensions.mediumAnim, curve: Curves.easeOutBack),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: context.text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(auth.isGuest ? AppIcons.lock : AppIcons.seal, size: 13, color: c.textTertiary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(subtitle, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: _HeaderStat(label: 'Cards', value: '${wallet.cards.length}')),
                      const SizedBox(width: 8),
                      Expanded(child: _HeaderStat(label: 'In vault', value: '$secured', color: c.success)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeaderStat(
                          label: 'Yearly fees',
                          value: wallet.totalAnnualFees == 0 ? '₹0' : CurrencyFormatter.compact(wallet.totalAnnualFees),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _HeaderStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: AppDimensions.roundedMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.numeric(18, color: color ?? c.textPrimary)),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _GuestUpsell extends StatelessWidget {
  const _GuestUpsell();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppSurface(
        tone: SurfaceTone.accent,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconHalo(icon: AppIcons.shieldStar, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create a free account', style: context.text.titleSmall),
                  Text(
                    'Sync card names across devices and get smarter picks. Numbers & CVVs never leave this phone.',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'Sign in',
              compact: true,
              expand: false,
              onPressed: () => context.read<AuthProvider>().exitGuest(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final mode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return SettingsGroup(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              for (final (m, icon, label) in [
                (ThemeMode.system, AppIcons.themeSystem, 'System'),
                (ThemeMode.light, AppIcons.themeLight, 'Light'),
                (ThemeMode.dark, AppIcons.themeDark, 'Dark'),
              ]) ...[
                Expanded(
                  child: _ThemeOption(
                    icon: icon,
                    label: label,
                    mode: m,
                    selected: mode == m,
                  ),
                ),
                if (m != ThemeMode.dark) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode mode;
  final bool selected;

  const _ThemeOption({required this.icon, required this.label, required this.mode, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final previewDark = mode == ThemeMode.dark || (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final bg = previewDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fg = previewDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;

    return PressableScale(
      onTap: () => context.read<SettingsProvider>().setThemeMode(mode),
      child: AnimatedContainer(
        duration: AppDimensions.fastAnim,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: AppDimensions.roundedMd,
          border: Border.all(color: selected ? c.accent : c.border, width: selected ? 1.6 : 1),
          color: selected ? c.tint(c.accent, 0.08) : Colors.transparent,
        ),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: AppDimensions.roundedSm,
                border: Border.all(color: c.border),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 26, height: 5, decoration: BoxDecoration(color: AppColors.gold, borderRadius: AppDimensions.roundedFull)),
                  const SizedBox(height: 4),
                  Container(height: 5, decoration: BoxDecoration(color: fg, borderRadius: AppDimensions.roundedFull)),
                  const SizedBox(height: 4),
                  Container(width: 34, height: 5, decoration: BoxDecoration(color: fg, borderRadius: AppDimensions.roundedFull)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: selected ? c.accent : c.textSecondary),
                const SizedBox(width: 4),
                Text(label, style: context.text.labelMedium!.copyWith(color: selected ? c.textPrimary : c.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  Future<void> _toggleAppLock(BuildContext context, bool enable) async {
    final settings = context.read<SettingsProvider>();
    if (enable) {
      final status = await context.read<SecureVaultService>().authenticate(reason: 'Confirm to turn on app lock');
      if (!context.mounted) return;
      if (!status.isSuccess) {
        if (status != VaultStatus.cancelled) AppToast.warning(context, message: status.message);
        return;
      }
    }
    settings.setAppLock(enable);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<SettingsProvider>().settings;
    return SettingsGroup(
      title: 'Security',
      footer: 'Copying or revealing card details always asks for biometrics.',
      children: [
        SettingsSwitchTile(
          icon: AppIcons.fingerprint,
          iconColor: c.accent,
          title: 'App lock',
          subtitle: 'Ask for biometrics when opening the app',
          value: s.appLockEnabled,
          onChanged: (v) => _toggleAppLock(context, v),
        ),
        SettingsSwitchTile(
          icon: AppIcons.screenshot,
          iconColor: c.info,
          title: 'Hide in screenshots',
          subtitle: 'Blocks screenshots & blurs the app switcher',
          value: s.blockScreenshots,
          onChanged: (v) => context.read<SettingsProvider>().setBlockScreenshots(v),
        ),
        SettingsTile(
          icon: AppIcons.clipboard,
          iconColor: c.success,
          title: 'Clear clipboard after',
          value: '${s.clipboardClearSeconds}s',
          onTap: () => _pickSeconds(
            context,
            title: 'Clear clipboard after',
            options: AppSettings.clipboardOptions,
            current: s.clipboardClearSeconds,
            onPicked: context.read<SettingsProvider>().setClipboardSeconds,
          ),
        ),
        SettingsTile(
          icon: AppIcons.countdown,
          iconColor: c.warning,
          title: 'Hide revealed details after',
          value: '${s.revealSeconds}s',
          onTap: () => _pickSeconds(
            context,
            title: 'Hide revealed details after',
            options: AppSettings.revealOptions,
            current: s.revealSeconds,
            onPicked: context.read<SettingsProvider>().setRevealSeconds,
          ),
        ),
        SettingsSwitchTile(
          icon: AppIcons.vibrate,
          title: 'Haptic feedback',
          value: s.hapticsEnabled,
          onChanged: (v) => context.read<SettingsProvider>().setHaptics(v),
        ),
      ],
    );
  }
}

void _pickSeconds(
  BuildContext context, {
  required String title,
  required List<int> options,
  required int current,
  required ValueChanged<int> onPicked,
}) {
  showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: title),
          for (final o in options)
            ListTile(
              title: Text(o < 60 ? '$o seconds' : '${o ~/ 60} minute${o >= 120 ? 's' : ''}'),
              trailing: o == current ? Icon(AppIcons.check, color: ctx.colors.accent, size: 18) : null,
              onTap: () {
                onPicked(o);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _DataSection extends StatelessWidget {
  const _DataSection();

  Future<void> _eraseVault(BuildContext context) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Erase secure vault?',
      message: 'All saved card numbers, CVVs and expiry dates on this device will be permanently deleted. Your cards stay in the wallet with last 4 digits only.',
      confirmLabel: 'Erase vault',
      icon: AppIcons.keyhole,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final vault = context.read<SecureVaultService>();
    final status = await vault.authenticate(reason: 'Confirm to erase the vault');
    if (!status.isSuccess || !context.mounted) return;
    await vault.clearAll();
    if (!context.mounted) return;
    await context.read<WalletProvider>().loadCards();
    if (context.mounted) AppToast.success(context, message: 'Vault erased');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SettingsGroup(
      title: 'Data',
      children: [
        SettingsTile(
          icon: AppIcons.refresh,
          title: 'Sync wallet',
          subtitle: 'Refresh cards and catalog data',
          onTap: () async {
            await Future.wait([
              context.read<WalletProvider>().loadCards(isRefresh: true),
              context.read<CatalogProvider>().refresh(),
            ]);
            if (context.mounted) AppToast.success(context, message: 'Up to date');
          },
        ),
        SettingsTile(
          icon: AppIcons.broom,
          title: 'Clear cached catalog',
          subtitle: 'Frees space; re-downloads when needed',
          onTap: () async {
            await context.read<CatalogProvider>().clearCache();
            if (context.mounted) AppToast.success(context, message: 'Cache cleared');
          },
        ),
        SettingsTile(
          icon: AppIcons.keyhole,
          title: 'Erase secure vault',
          subtitle: 'Delete all card numbers & CVVs from this device',
          iconColor: c.danger,
          destructive: true,
          onTap: () => _eraseVault(context),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: 'About',
      children: [
        SettingsTile(
          icon: AppIcons.shield,
          title: 'How your data is protected',
          onTap: () => _showProtectionSheet(context),
        ),
        SettingsTile(
          icon: AppIcons.question,
          title: 'How recommendations work',
          onTap: () => _showInfoSheet(
            context,
            title: 'How recommendations work',
            points: const [
              'Pick a category and amount on Home — CreditVance ranks every card in your wallet for that spend.',
              'Signed-in wallets are ranked by the CreditVance engine; guest wallets are ranked on this device.',
              'We also show the best card in the market so you know what you might be missing.',
              'International spends account for forex markup and GST on it.',
            ],
          ),
        ),
        SettingsTile(
          icon: AppIcons.document,
          title: 'Privacy & terms',
          onTap: () => _showInfoSheet(
            context,
            title: 'Privacy & terms',
            points: const [
              'We never collect card numbers, CVVs or expiry dates.',
              'Account data is limited to your name, email and card nicknames / last 4 digits.',
              'You can erase the on-device vault any time from Account → Data.',
            ],
          ),
        ),
      ],
    );
  }
}

void _showProtectionSheet(BuildContext context) {
  final c = context.colors;
  final items = [
    (AppIcons.keyhole, 'Hardware encryption', 'Card numbers and CVVs are encrypted with keys held in Android Keystore / iOS Secure Enclave.'),
    (AppIcons.fingerprint, 'Biometric gate', 'Every copy or reveal needs your fingerprint or face.'),
    (AppIcons.clipboard, 'Self-clearing clipboard', 'Copied details are marked sensitive and wiped automatically.'),
    (AppIcons.screenshot, 'Screen protection', 'Screenshots and screen recording are blocked; the app switcher is blurred.'),
    (AppIcons.lock, 'Zero-knowledge', 'Sensitive card data is never sent to our servers — not even encrypted.'),
  ];
  showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How your data is protected', style: ctx.text.headlineSmall),
            const SizedBox(height: 16),
            for (final (icon, title, body) in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconHalo(icon: icon, color: c.success, size: 34, iconSize: 17),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: ctx.text.titleSmall),
                          const SizedBox(height: 2),
                          Text(body, style: ctx.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void _showInfoSheet(BuildContext context, {required String title, required List<String> points}) {
  showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ctx.text.headlineSmall),
            const SizedBox(height: 12),
            for (final p in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(AppIcons.checkCircle, size: 13, color: ctx.colors.success),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p, style: ctx.text.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  Future<void> _signOut(BuildContext context) async {
    final isGuest = context.read<AuthProvider>().isGuest;
    final ok = await showConfirmSheet(
      context,
      title: isGuest ? 'Reset this device?' : 'Sign out?',
      message: isGuest
          ? 'Your wallet and all saved card details on this device will be deleted.'
          : 'Saved card numbers and CVVs will be erased from this device. Your cards stay in your account and can be re-secured after signing in.',
      confirmLabel: isGuest ? 'Reset' : 'Sign out',
      icon: AppIcons.signOut,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final wallet = context.read<WalletProvider>();
    final vault = context.read<SecureVaultService>();
    final auth = context.read<AuthProvider>();
    await wallet.reset(eraseLocal: true);
    await vault.clearAll();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<AuthProvider, bool>((a) => a.isGuest);
    return AppButton(
      label: isGuest ? 'Reset device' : 'Sign out',
      icon: AppIcons.signOut,
      variant: AppButtonVariant.danger,
      onPressed: () => _signOut(context),
    );
  }
}
