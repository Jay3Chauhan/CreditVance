import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/luxury_text_field.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/auth_provider.dart';

/// User Profile, Security Vault settings, and Authentication Controls.
/// Strictly Zero setState: Uses Provider Consumers and ValueNotifier.
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

    return SingleChildScrollView(
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
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(AppIcons.lock, size: 30, color: AppColors.canvasDark),
                      ),
                    ),
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

              // Mode Switcher Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticsHelper.selection();
                          isLoginModeNotifier.value = true;
                          context.read<AuthProvider>().clearError();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isLogin ? AppColors.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: AppTypography.labelLarge.copyWith(
                                color: isLogin ? AppColors.canvasDark : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticsHelper.selection();
                          isLoginModeNotifier.value = false;
                          context.read<AuthProvider>().clearError();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isLogin ? AppColors.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Center(
                            child: Text(
                              'Create Account',
                              style: AppTypography.labelLarge.copyWith(
                                color: !isLogin ? AppColors.canvasDark : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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

              // Full Name field (Register only)
              if (!isLogin) ...[
                LuxuryTextField(
                  label: 'Full Name',
                  hint: 'e.g. Jay Vardhan',
                  controller: nameController,
                  prefixIcon: AppIcons.user,
                ),
                const SizedBox(height: AppDimensions.p16),
              ],

              // Email field
              LuxuryTextField(
                label: 'Email Address',
                hint: 'user@cardsage.app',
                controller: emailController,
                prefixIcon: AppIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppDimensions.p16),

              // Password field with visibility toggle
              ValueListenableBuilder<bool>(
                valueListenable: isObscurePasswordNotifier,
                builder: (context, isObscure, _) {
                  return LuxuryTextField(
                    label: 'Master Password',
                    hint: '••••••••••••',
                    controller: passwordController,
                    obscureText: isObscure,
                    prefixIcon: AppIcons.lock,
                    suffix: IconButton(
                      icon: Icon(
                        isObscure ? AppIcons.eyeSlash : AppIcons.eye,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        isObscurePasswordNotifier.value = !isObscurePasswordNotifier.value;
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: AppDimensions.p24),

              // Submit Button
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isLoading = auth.state == ViewState.loading;

                  return LuxuryButton(
                    label: isLogin ? 'Sign In to Vault' : 'Create Vault Account',
                    isLoading: isLoading,
                    variant: LuxuryButtonVariant.primary,
                    onPressed: () async {
                      HapticsHelper.medium();
                      final email = emailController.text.trim();
                      final pass = passwordController.text.trim();
                      final name = nameController.text.trim();

                      if (email.isEmpty || pass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter email and password.')),
                        );
                        return;
                      }

                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final walletProv = context.read<WalletProvider>();

                      bool success;
                      if (isLogin) {
                        success = await auth.login(email, pass);
                      } else {
                        success = await auth.register(email, pass, name.isEmpty ? 'User' : name);
                      }

                      if (success) {
                        await walletProv.loadCards(isRefresh: true);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isLogin ? 'Welcome back, ${auth.user?.fullName}!' : 'Account registered successfully!',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: AppDimensions.p20),

              // Quick Access Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR INSTANT ACCESS',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                ],
              ),

              const SizedBox(height: AppDimensions.p20),

              // One-Tap Demo Login Button
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return LuxuryButton(
                    label: '⚡ One-Tap Demo Sign In (Jay)',
                    variant: LuxuryButtonVariant.secondary,
                    isLoading: auth.state == ViewState.loading,
                    onPressed: () async {
                      HapticsHelper.light();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final walletProv = context.read<WalletProvider>();
                      final success = await auth.loginAsDemo();
                      if (success) {
                        await walletProv.loadCards(isRefresh: true);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Signed in as Demo User (Jay).')),
                        );
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
    );
  }
}

/// Authenticated Profile Screen showing User Card, Enclave Controls, and Logout action.
/// Strictly Zero setState: Uses Provider Consumers.
class _AuthenticatedProfileView extends StatelessWidget {
  final AuthProvider auth;

  const _AuthenticatedProfileView({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;

    return SingleChildScrollView(
      padding: AppDimensions.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header Card
          LuxuryGlassCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: AppTypography.headlineLarge.copyWith(color: AppColors.canvasDark),
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const LuxuryBadge(
                            label: 'Vault Authenticated',
                            icon: AppIcons.shieldCheck,
                            variant: LuxuryBadgeVariant.emerald,
                            isSmall: true,
                          ),
                          const SizedBox(width: 8),
                          LuxuryBadge(
                            label: 'ID: ${user.id}',
                            variant: LuxuryBadgeVariant.neutral,
                            isSmall: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.p24),

          // Vault Security Settings
          Text('Hardware Security & Enclave', style: AppTypography.titleSmall),
          const SizedBox(height: AppDimensions.p12),

          LuxuryGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.faceId, color: AppColors.gold),
                  title: Text('Biometric Authentication', style: AppTypography.titleSmall),
                  subtitle: Text('Required to copy or unmask card PAN', style: AppTypography.bodySmall),
                  trailing: const LuxuryBadge(
                    label: 'Enforced',
                    variant: LuxuryBadgeVariant.gold,
                    isSmall: true,
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.lock, color: AppColors.emerald),
                  title: Text('Zero-Knowledge Isolation', style: AppTypography.titleSmall),
                  subtitle: Text('Full card numbers never leave device', style: AppTypography.bodySmall),
                  trailing: const LuxuryBadge(
                    label: 'Active',
                    variant: LuxuryBadgeVariant.emerald,
                    isSmall: true,
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.copy, color: AppColors.sapphire),
                  title: Text('Auto-Clear Clipboard', style: AppTypography.titleSmall),
                  subtitle: Text('Purges copied PAN after 30 seconds', style: AppTypography.bodySmall),
                  trailing: const LuxuryBadge(
                    label: '30s Timer',
                    variant: LuxuryBadgeVariant.sapphire,
                    isSmall: true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.p24),

          // Backend Connectivity Configuration
          Text('Backend API Integration', style: AppTypography.titleSmall),
          const SizedBox(height: AppDimensions.p12),

          LuxuryGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Target URL', style: AppTypography.labelSmall),
                    const LuxuryBadge(
                      label: 'FastAPI Live',
                      variant: LuxuryBadgeVariant.emerald,
                      isSmall: true,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ApiEndpoints.baseUrl,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fully connected with real-time HTTP logging interceptor enabled.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.p32),

          // Logout Button with Confirmation Dialog
          LuxuryButton(
            label: 'Log Out of CardSage',
            variant: LuxuryButtonVariant.danger,
            onPressed: () {
              HapticsHelper.medium();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
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
                    title: Text('Log Out of Vault?', style: AppTypography.headlineMedium),
                    content: Text(
                      'All temporary unmasked vault credentials and active session tokens will be securely purged from this device.',
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
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Logged out of session.')),
                          );
                        },
                        child: Text(
                          'Log Out',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: AppDimensions.p32),
        ],
      ),
    );
  }
}
