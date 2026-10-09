import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../remote_config/presentation/remote_config_controller.dart';
import '../../../wallet/presentation/widgets/visual_credit_card.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = context.screenWidth >= 900;
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  const Expanded(child: _Hero(large: true)),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimensions.p32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: const _AuthForm(),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: const Column(
                      children: [
                        _Hero(large: false),
                        SizedBox(height: AppDimensions.p24),
                        _AuthForm(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool large;
  const _Hero({required this.large});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cardWidth = large ? 320.0 : 220.0;

    final stack = SizedBox(
      height: cardWidth / AppDimensions.cardAspectRatio + (large ? 70 : 44),
      width: cardWidth + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(22, -18),
            child: Transform.rotate(
              angle: 0.12,
              child: SizedBox(
                width: cardWidth,
                child: const VisualCreditCard(
                  elevation: 0.6,
                  data: CardFaceData(bankName: 'Axis Bank', cardName: 'Atlas', network: 'Visa', last4: '2044'),
                ),
              ),
            ),
          )
              .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
              .moveY(begin: 0, end: -6, duration: 2600.ms, curve: Curves.easeInOut),
          Transform.rotate(
            angle: -0.06,
            child: SizedBox(
              width: cardWidth,
              child: const VisualCreditCard(
                data: CardFaceData(bankName: 'HDFC Bank', cardName: 'Infinia Metal', network: 'Visa', last4: '4821'),
              ),
            ),
          )
              .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
              .moveY(begin: 0, end: 6, duration: 3000.ms, curve: Curves.easeInOut),
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.slowAnim).scale(begin: const Offset(0.94, 0.94));

    return Container(
      decoration: large
          ? BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.0,
                colors: [c.tint(c.accent, 0.14), c.canvas],
              ),
            )
          : null,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          stack,
          SizedBox(height: large ? AppDimensions.p32 : AppDimensions.p16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                child: const Icon(AppIcons.keyhole, size: 14, color: AppColors.black),
              ),
              const SizedBox(width: 8),
              Text(AppStrings.appName, style: AppTypography.numeric(large ? 26 : 22, color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(AppStrings.appTagline, style: context.text.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm();

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

/// Owns text controllers and the form key; UI toggles use ValueNotifiers.
class _AuthFormState extends State<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _isSignUp = ValueNotifier<bool>(false);
  final _obscure = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _isSignUp.dispose();
    _obscure.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final ok = _isSignUp.value
        ? await auth.register(_email.text, _password.text, _name.text)
        : await auth.login(_email.text, _password.text);
    if (!ok && mounted) {
      AppToast.error(context, message: auth.errorMessage ?? AppStrings.generalError);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    final emailError = AuthRepositoryImpl.validateEmail(email);
    if (emailError != null) {
      AppToast.info(context, message: emailError);
      return;
    }
    final result = await context.read<AuthProvider>().forgotPassword(email);
    if (!mounted) return;
    final token = result.dataOrNull;
    if (!result.isSuccess) {
      AppToast.error(context, message: result.errorOrNull ?? 'Could not start a reset');
      return;
    }
    if (token == null || token.isEmpty) {
      AppToast.success(context, message: 'If that account exists, reset instructions are on the way');
      return;
    }
    final next = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose a new password'),
        content: AppTextField(controller: next, label: 'New password', obscureText: true, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    final password = next.text;
    next.dispose();
    if (saved != true || !mounted) return;
    if (password.length < 8) {
      AppToast.info(context, message: 'Use at least 8 characters');
      return;
    }
    final ok = await context.read<AuthProvider>().resetPassword(token: token, newPassword: password);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, message: 'Password updated. Sign in with it.');
    } else {
      AppToast.error(context, message: context.read<AuthProvider>().errorMessage ?? 'Could not reset the password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final guestMode = context.select<RemoteConfigController, bool>((remote) => remote.config.guestModeEnabled);
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isSignUp,
          builder: (context, isSignUp, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ModeSwitch(
                  isSignUp: isSignUp,
                  onChanged: (v) {
                    _isSignUp.value = v;
                    context.read<AuthProvider>().clearError();
                  },
                ),
                const SizedBox(height: AppDimensions.p20),
                AnimatedSize(
                  duration: AppDimensions.mediumAnim,
                  curve: Curves.easeOutCubic,
                  child: isSignUp
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.p14),
                          child: AppTextField(
                            controller: _name,
                            label: 'Full name',
                            hint: 'Aarav Sharma',
                            prefixIcon: AppIcons.user,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: AppIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => AuthRepositoryImpl.validateEmail(v ?? ''),
                ),
                const SizedBox(height: AppDimensions.p14),
                ValueListenableBuilder<bool>(
                  valueListenable: _obscure,
                  builder: (context, obscure, _) => AppTextField(
                    controller: _password,
                    label: 'Password',
                    hint: isSignUp ? 'At least 8 characters' : '••••••••',
                    prefixIcon: AppIcons.lockKey,
                    obscureText: obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    autofillHints: [isSignUp ? AutofillHints.newPassword : AutofillHints.password],
                    validator: (v) => AuthRepositoryImpl.validatePassword(v ?? '', isSignUp: isSignUp),
                    suffix: IconButton(
                      onPressed: () => _obscure.value = !obscure,
                      icon: Icon(obscure ? AppIcons.eye : AppIcons.eyeSlash, size: 18, color: c.textTertiary),
                    ),
                  ),
                ),
                if (!isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton.ghost(label: 'Forgot password?', onPressed: _forgot),
                  ),
                const SizedBox(height: AppDimensions.p12),
                Selector<AuthProvider, bool>(
                  selector: (_, p) => p.isBusy,
                  builder: (context, busy, _) => AppButton(
                    label: isSignUp ? 'Create account' : 'Sign in',
                    icon: AppIcons.arrowRight,
                    trailingIcon: true,
                    isLoading: busy,
                    onPressed: _submit,
                  ),
                ),
                if (guestMode) ...[
                  const SizedBox(height: AppDimensions.p16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: context.text.bodySmall),
                      ),
                      Expanded(child: Divider(color: c.border)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  AppButton.outline(
                    label: 'Continue without an account',
                    icon: AppIcons.lock,
                    onPressed: () => context.read<AuthProvider>().continueAsGuest(),
                  ),
                ],
                const SizedBox(height: AppDimensions.p20),
                const _PrivacyNote(),
              ],
            ).animate().fadeIn(duration: AppDimensions.mediumAnim, delay: 120.ms).slideY(begin: 0.03, end: 0);
          },
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  const _ModeSwitch({required this.isSignUp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget segment(String label, bool active, VoidCallback onTap) => Expanded(
          child: PressableScale(
            onTap: onTap,
            child: SizedBox(
              height: 38,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: AppDimensions.fastAnim,
                  style: context.text.labelLarge!.copyWith(color: active ? c.textPrimary : c.textTertiary),
                  child: Text(label),
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppDimensions.roundedMd),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: AppDimensions.mediumAnim,
            curve: Curves.easeOutCubic,
            alignment: isSignUp ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppDimensions.roundedSm,
                  boxShadow: [BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              segment('Sign in', !isSignUp, () => onChanged(false)),
              segment('Create account', isSignUp, () => onChanged(true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.shieldFill, size: 16, color: c.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your account only syncs card names and last 4 digits. Card numbers and CVVs stay encrypted on this device.',
            style: context.text.bodySmall,
          ),
        ),
      ],
    );
  }
}
