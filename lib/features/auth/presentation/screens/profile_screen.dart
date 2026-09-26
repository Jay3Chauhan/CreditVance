import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/luxury_text_field.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/auth_provider.dart';

/// User Profile, Security Vault settings, and Authentication Controls.
/// Strictly Zero setState: Uses Provider Consumers and ValueNotifier.
/// Professional, clean MNC fintech design with zero clutter.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account & Security', style: AppTypography.headlineLarge),
            Text(
              'Zero-Knowledge Privacy Controls',
              style: AppTypography.labelSmall.copyWith(color: AppColors.goldLight),
            ),
          ],
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated || auth.user == null) {
            return const _UnauthenticatedAuthView();
          }

          return _AuthenticatedProfileView(auth: auth);
        },
      ),
    );
  }
}

/// Unauthenticated View providing Sign In, Registration, and One-Tap Demo Login.
/// Strictly Zero setState: Uses ValueNotifier for view switching and password toggles.
class _UnauthenticatedAuthView extends StatelessWidget {
  const _UnauthenticatedAuthView();

  @override
  Widget build(BuildContext context) {
    final isLoginModeNotifier = ValueNotifier<bool>(true);
    final isObscurePasswordNotifier = ValueNotifier<bool>(true);

    final emailController = TextEditingController(text: 'jay@cardsage.app');
    final passwordController = TextEditingController(text: 'Password123!');
    final nameController = TextEditingController(text: 'Jay');

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surfaceSecondary,
      onRefresh: () => context.read<AuthProvider>().init(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppDimensions.screenPadding,
        child: ValueListenableBuilder<bool>(
          valueListenable: isLoginModeNotifier,
          builder: (context, isLogin, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                LuxuryGlassCard(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(AppIcons.lock, size: 30, color: AppColors.canvasDark),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .custom(
                            duration: 2200.ms,
                            curve: Curves.easeInOut,
                            builder: (ctx, value, child) {
                              return DecoratedBox(
                                position: DecorationPosition.foreground,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gold.withOpacity(0.18 + value * 0.35),
                                      blurRadius: 20 + value * 18,
                                      spreadRadius: value * 4,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                          )
                          .fadeIn(duration: 500.ms),
                      const SizedBox(height: AppDimensions.p16),
                      Text(
                        isLogin ? 'Sign In to Your Vault' : 'Create Vault Account',
                        style: AppTypography.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Access hardware-encrypted card portfolios and real-time reward optimizers.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.p20),

                // Mode Switcher Tabs with smooth sliding pill
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tabWidth = constraints.maxWidth / 2;
                      return Stack(
                        children: [
                          AnimatedAlign(
                            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
                            duration: AppDimensions.mediumAnim,
                            curve: Curves.fastOutSlowIn,
                            child: Container(
                              width: tabWidth,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticsHelper.selection();
                                    isLoginModeNotifier.value = true;
                                    context.read<AuthProvider>().clearError();
                                  },
                                  child: Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: AnimatedDefaultTextStyle(
                                      duration: AppDimensions.fastAnim,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: isLogin ? AppColors.canvasDark : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: const Text('Sign In'),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticsHelper.selection();
                                    isLoginModeNotifier.value = false;
                                    context.read<AuthProvider>().clearError();
                                  },
                                  child: Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: AnimatedDefaultTextStyle(
                                      duration: AppDimensions.fastAnim,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: !isLogin ? AppColors.canvasDark : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: const Text('Create Account'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.p20),

                // Error Banner (if any)
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.errorMessage == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.p16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(AppIcons.alertCircle, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Form Fields
                if (!isLogin) ...[
                  LuxuryTextField(
                    label: 'Full Name',
                    hint: 'e.g. Jay Chauhan',
                    controller: nameController,
                    prefixIcon: AppIcons.user,
                  ),
                  const SizedBox(height: AppDimensions.p16),
                ],

                LuxuryTextField(
                  label: 'Email Address',
                  hint: 'name@example.com',
                  controller: emailController,
                  prefixIcon: AppIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: AppDimensions.p16),

                ValueListenableBuilder<bool>(
                  valueListenable: isObscurePasswordNotifier,
                  builder: (context, isObscure, _) {
                    return LuxuryTextField(
                      label: 'Vault Password',
                      hint: '••••••••••••',
                      controller: passwordController,
                      prefixIcon: AppIcons.lock,
                      obscureText: isObscure,
                      suffix: IconButton(
                        icon: Icon(
                          isObscure ? AppIcons.eye : AppIcons.eyeSlash,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          isObscurePasswordNotifier.value = !isObscure;
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.p24),

                // Primary CTA
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return LuxuryButton(
                      label: isLogin ? 'Open Security Vault' : 'Initialize Vault Account',
                      icon: AppIcons.unlock,
                      isLoading: auth.state == ViewState.loading,
                      onPressed: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();
                        final name = nameController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          AppToast.error(
                            context,
                            title: 'Validation Error',
                            message: 'Please fill in all credentials.',
                          );
                          return;
                        }

                        HapticsHelper.medium();
                        final walletProv = context.read<WalletProvider>();

                        if (isLogin) {
                          final success = await auth.login(email, password);
                          if (success) {
                            await walletProv.loadCards(isRefresh: true);
                            if (context.mounted) {
                              AppToast.success(
                                context,
                                title: 'Vault Decrypted',
                                message: 'Welcome back, ${auth.user?.fullName ?? "User"}!',
                              );
                            }
                          }
                        } else {
                          if (name.isEmpty) {
                            AppToast.error(
                              context,
                              title: 'Name Required',
                              message: 'Please enter your full name.',
                            );
                            return;
                          }
                          final success = await auth.register(
                            email,
                            password,
                            name,
                          );
                          if (success) {
                            await walletProv.loadCards(isRefresh: true);
                            if (context.mounted) {
                              AppToast.success(
                                context,
                                title: 'Account Initialized',
                                message: 'Vault profile ready for hardware storage.',
                              );
                            }
                          }
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.p16),

                // Demo User Quick Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return LuxuryButton(
                      label: 'One-Tap Demo Sign In (Jay)',
                      variant: LuxuryButtonVariant.secondary,
                      isLoading: auth.state == ViewState.loading,
                      onPressed: () async {
                        HapticsHelper.light();
                        final walletProv = context.read<WalletProvider>();
                        final success = await auth.loginAsDemo();
                        if (success) {
                          await walletProv.loadCards(isRefresh: true);
                          if (context.mounted) {
                            AppToast.success(
                              context,
                              title: 'Demo Access Granted',
                              message: 'Signed in as Demo User (Jay).',
                            );
                          }
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.p32),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Authenticated Profile Screen — Executive MNC Fintech Design.
/// Professional, structured, minimal chips, elegant typography and security diagnostics.
class _AuthenticatedProfileView extends StatelessWidget {
  final AuthProvider auth;

  const _AuthenticatedProfileView({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surfaceSecondary,
      onRefresh: () async {
        await Future.wait([
          auth.init(),
          context.read<WalletProvider>().loadCards(isRefresh: true),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Executive User Profile Hero
            LuxuryGlassCard(
              padding: const EdgeInsets.all(AppDimensions.p20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                        style: AppTypography.headlineLarge.copyWith(
                          color: AppColors.canvasDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: AppTypography.headlineMedium),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Vault Active • Encrypted On-Device',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.emeraldLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: AppDimensions.p16),

            // 2. Vault Snapshot Metrics Bar
            Consumer<WalletProvider>(
              builder: (context, walletProv, _) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'VAULT CARDS',
                        value: '${walletProv.cards.length} Cards',
                        icon: AppIcons.navWallet,
                        accentColor: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'CIPHER',
                        value: 'AES-256',
                        icon: AppIcons.lock,
                        accentColor: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'STORAGE',
                        value: 'KeyStore',
                        icon: AppIcons.shieldCheck,
                        accentColor: AppColors.sapphire,
                      ),
                    ),
                  ],
                );
              },
            ).animate(delay: 80.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: AppDimensions.p24),

            // 3. Security & Biometrics Group
            Text('Hardware Security & Policy', style: AppTypography.titleSmall)
                .animate(delay: 120.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: AppDimensions.p12),

            LuxuryGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _buildSecurityRow(
                    icon: AppIcons.faceId,
                    iconColor: AppColors.gold,
                    title: 'Biometric Verification',
                    subtitle: 'Required for copy & credential reveal',
                    statusText: 'Enforced',
                    statusColor: AppColors.emerald,
                  ),
                  const Divider(height: 1),
                  _buildSecurityRow(
                    icon: AppIcons.lock,
                    iconColor: AppColors.emerald,
                    title: 'Zero-Knowledge Isolation',
                    subtitle: 'Full PAN and CVV never transmitted',
                    statusText: 'Air-Gapped',
                    statusColor: AppColors.emerald,
                  ),
                  const Divider(height: 1),
                  _buildSecurityRow(
                    icon: AppIcons.copy,
                    iconColor: AppColors.sapphire,
                    title: 'Auto-Purge Clipboard',
                    subtitle: 'Clears copied PAN after 30 seconds',
                    statusText: '30s Active',
                    statusColor: AppColors.textSecondary,
                  ),
                ],
              ),
            ).animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: AppDimensions.p24),

            // 4. Vault Diagnostic Specifications
            Text('System & Privacy Specs', style: AppTypography.titleSmall)
                .animate(delay: 200.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: AppDimensions.p12),

            LuxuryGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildSpecRow('Encryption Engine', 'Android KeyStore / Secure Enclave'),
                  const Divider(height: 16),
                  _buildSpecRow('Network Outbound', '0 B (Zero card data sent)'),
                  const Divider(height: 16),
                  _buildSpecRow('Offline Database', 'Local Cache • Hardware Vault'),
                  const Divider(height: 16),
                  _buildSpecRow('Client Version', 'CardSage 1.0.0 (Enterprise)'),
                ],
              ),
            ).animate(delay: 240.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: AppDimensions.p32),

            // 5. Clean Action: Log Out
            LuxuryButton(
              label: 'Sign Out of Vault Session',
              variant: LuxuryButtonVariant.danger,
              onPressed: () {
                HapticsHelper.medium();
                final walletProv = context.read<WalletProvider>();

                showDialog(
                  context: context,
                  builder: (dialogCtx) {
                    return AlertDialog(
                      backgroundColor: AppColors.surfacePrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      title: Text('Lock and Sign Out?', style: AppTypography.headlineMedium),
                      content: Text(
                        'All temporary unmasked vault credentials and active session states will be securely purged from memory.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: Text(
                            'Cancel',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(dialogCtx).pop();
                            await auth.logout();
                            await walletProv.loadCards(isRefresh: true);
                            if (context.mounted) {
                              AppToast.info(
                                context,
                                title: 'Vault Locked',
                                message: 'Signed out of session safely.',
                              );
                            }
                          },
                          child: Text(
                            'Lock Vault',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ).animate(delay: 280.ms).fadeIn(duration: 350.ms),

            const SizedBox(height: AppDimensions.p32),
          ],
        ),
      ),
    );
  }

  /// Metric Tile for high-level vault status
  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Clean security policy row without chip clutter
  Widget _buildSecurityRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 13.5)),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: AppTypography.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Clean spec key-value row
  Widget _buildSpecRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
