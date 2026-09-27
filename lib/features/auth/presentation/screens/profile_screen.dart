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
import '../../../../core/firebase/messaging_service.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../remote_config/presentation/open_remote_link.dart';
import '../../../remote_config/presentation/remote_config_controller.dart';
import '../../../content/content_actions.dart';
import '../../../content/data/content_repository.dart';
import '../../../content/presentation/screens/help_screen.dart';
import '../../../content/presentation/screens/shortlist_screen.dart';
import '../../../../core/widgets/app_text_field.dart';
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
                const _AccountLinks(),
                const _AppearanceSection(),
                const _SecuritySection(),
                const _DataSection(),
                const _PrivacySection(),
                const _AboutSection(),
                const SizedBox(height: AppDimensions.p24),
                const _SignOutButton(),
                const SizedBox(height: AppDimensions.p16),
                Center(
                  child: Text(
                    '${AppStrings.appName} ${context.select<RemoteConfigController, String>((c) => c.versionLabel)}',
                    style: context.text.labelSmall,
                  ),
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
      automaticallyImplyLeading: false,
      expandedHeight: 220,
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
              padding: EdgeInsets.fromLTRB(context.gutter(), 8, context.gutter(), 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
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
                  const SizedBox(height: 16),
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

class _AccountLinks extends StatelessWidget {
  const _AccountLinks();

  Future<void> _editName(BuildContext context) async {
    final current = context.read<AuthProvider>().user?.fullName ?? '';
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: AppTextField(controller: controller, label: 'Full name', autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.length < 2 || !context.mounted) return;
    final ok = await context.read<AuthProvider>().updateName(name);
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, message: 'Name updated');
    } else {
      AppToast.error(context, message: context.read<AuthProvider>().errorMessage ?? 'Could not update your name');
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This permanently deletes your account and the cards stored with it. Card numbers on this phone are erased too.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final auth = context.read<AuthProvider>();
    final deleted = await auth.deleteAccount();
    if (!context.mounted) return;
    if (!deleted) {
      AppToast.error(context, message: auth.errorMessage ?? 'Could not delete the account');
      return;
    }
    final wallet = context.read<WalletProvider>();
    final vault = context.read<SecureVaultService>();
    await wallet.reset(eraseLocal: true);
    await vault.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AuthProvider, bool>((a) => a.isSignedIn);
    return SettingsGroup(
      title: 'Account',
      children: [
        if (signedIn)
          SettingsTile(
            icon: AppIcons.edit,
            title: 'Edit name',
            subtitle: context.select<AuthProvider, String>((a) => a.user?.fullName ?? ''),
            onTap: () => _editName(context),
          ),
        SettingsTile(
          icon: AppIcons.bookmark,
          title: 'Shortlist',
          subtitle: 'Cards you might apply for',
          onTap: () {
            if (!context.read<AuthProvider>().isSignedIn) {
              AppToast.info(context, message: 'Sign in to keep a shortlist');
              return;
            }
            ShortlistScreen.open(context);
          },
        ),
        SettingsTile(
          icon: AppIcons.question,
          title: 'Help',
          subtitle: 'Wallet, advisor, privacy',
          onTap: () => HelpScreen.open(context),
        ),
        if (signedIn)
          SettingsTile(
            icon: AppIcons.delete,
            title: 'Delete account',
            subtitle: 'Required by the app stores. Removes your account.',
            iconColor: context.colors.danger,
            destructive: true,
            onTap: () => _deleteAccount(context),
          ),
      ],
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

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    final diagnostics = context.select<SettingsProvider, bool>((s) => s.settings.diagnosticsEnabled);
    final push = context.select<RemoteConfigController, bool>((c) => c.config.pushEnabled);
    return SettingsGroup(
      title: 'Privacy',
      footer: 'Usage data and crash reports help us fix problems. They never include card numbers or CVVs.',
      children: [
        SettingsSwitchTile(
          icon: AppIcons.chartBar,
          title: 'Usage & crash reports',
          subtitle: 'Share anonymous analytics and crash reports',
          value: diagnostics,
          onChanged: context.read<SettingsProvider>().setDiagnostics,
        ),
        if (push)
          SettingsTile(
            icon: AppIcons.bell,
            title: 'Notifications',
            subtitle: 'Alerts for updates and announcements',
            onTap: () => _enableNotifications(context),
          ),
      ],
    );
  }
}

Future<void> _enableNotifications(BuildContext context) async {
  final result = await MessagingService.requestPermission();
  if (!context.mounted) return;
  switch (result) {
    case PushPermission.granted:
      AppToast.success(context, message: 'Notifications are on');
    case PushPermission.denied:
      AppToast.warning(context, message: 'Notifications are off. You can enable them in system settings.');
    case PushPermission.unavailable:
      AppToast.info(context, message: 'Notifications are not available on this device yet');
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteConfigController>();
    final support = remote.config.supportEmail;
    final help = remote.config.helpUrl;
    return SettingsGroup(
      title: 'About',
      children: [
        SettingsTile(
          icon: AppIcons.refresh,
          title: 'Check for updates',
          subtitle: remote.refreshing ? 'Checking…' : 'Looks at the latest app settings',
          onTap: remote.refreshing ? null : () => _checkForUpdates(context),
        ),
        if (support != null)
          SettingsTile(
            icon: AppIcons.mail,
            title: 'Contact support',
            subtitle: support,
            onTap: () => openRemoteLink(context, 'mailto:$support'),
          ),
        if (help != null)
          SettingsTile(
            icon: AppIcons.question,
            title: 'Help center',
            onTap: () => openRemoteLink(context, help),
          ),
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
              'Pick a category and amount on Home — Credvert ranks every card in your wallet for that spend.',
              'Signed-in wallets are ranked by the Credvert engine; guest wallets are ranked on this device.',
              'We also show the best card in the market so you know what you might be missing.',
              'International spends account for forex markup and GST on it.',
            ],
          ),
        ),
        SettingsTile(
          icon: AppIcons.document,
          title: 'Privacy policy',
          onTap: () => _openLegal(context, privacy: true),
        ),
        SettingsTile(
          icon: AppIcons.document,
          title: 'Terms of service',
          onTap: () => _openLegal(context, privacy: false),
        ),
      ],
    );
  }
}

Future<void> _checkForUpdates(BuildContext context) async {
  final remote = context.read<RemoteConfigController>();
  await remote.refresh(userInitiated: true);
  if (!context.mounted) return;
  if (remote.maintenanceActive || remote.forceUpdate || remote.softUpdate) return;
  if (remote.lastError != null) {
    AppToast.warning(context, message: remote.lastError!);
    return;
  }
  AppToast.success(context, message: "You're on the latest version");
}

Future<void> _openLegal(BuildContext context, {required bool privacy}) async {
  final result = await context.read<ContentRepository>().legal();
  if (!context.mounted) return;
  final links = result.dataOrNull;
  var url = privacy ? links?.privacyPolicyUrl : links?.termsUrl;
  if (url == null || url.isEmpty) {
    final config = context.read<RemoteConfigController>().config;
    url = privacy ? config.privacyPolicyUrl : config.termsUrl;
  }
  if (url == null || url.isEmpty) {
    AppToast.error(context, message: 'That page is not available right now');
    return;
  }
  await openExternalUrl(context, url);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(AppIcons.signOut, color: ctx.colors.danger),
        title: Text(isGuest ? 'Reset this device?' : 'Sign out?'),
        content: Text(
          isGuest
              ? 'Your wallet and all saved card details on this device will be deleted.'
              : 'Saved card numbers and CVVs will be erased from this device. Your cards stay in your account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isGuest ? 'Reset' : 'Sign out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
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
