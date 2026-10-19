import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/widgets/luxury_button.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../domain/entities/sms_tracking_status.dart';
import '../providers/expense_provider.dart';

/// Busy flag for the consent CTA, scoped to the consent route.
class _ConsentBusy extends ValueNotifier<bool> {
  _ConsentBusy() : super(false);
}

/// Prominent disclosure + affirmative consent shown BEFORE the Android runtime
/// SMS permission dialog (Google Play User Data policy; DPDP itemised notice).
class SmsConsentScreen extends StatelessWidget {
  const SmsConsentScreen({super.key});

  /// Pushes the consent screen with its scoped micro-state.
  static Future<void> open(BuildContext context) {
    HapticsHelper.light();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<_ConsentBusy>(
          create: (_) => _ConsentBusy(),
          child: const SmsConsentScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text('SMS Spend Tracking', style: AppTypography.headlineLarge.copyWith(color: c.textPrimary))),
      body: SafeArea(
        child: ListView(
          padding: AppDimensions.screenPadding,
          children: [
            Center(
              child: Container(
                width: AppDimensions.avatarLg,
                height: AppDimensions.avatarLg,
                decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                child: Icon(AppIcons.sms, color: c.onAccent, size: AppDimensions.p32),
              ).animate().scale(duration: AppDimensions.springAnim, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: AppDimensions.p16),
            Text(AppStrings.smsConsentTitle, style: AppTypography.displayMedium.copyWith(color: c.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.p8),
            Text(
              'Automatically track where, on which card and how much you spend — like CRED or CheQ, '
              'but your SMS text never leaves this phone.',
              style: AppTypography.bodyLarge.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.p24),
            _DisclosureBlock(
              icon: AppIcons.search,
              accent: c.accent,
              title: 'What we read',
              points: const [
                'Only SMS from registered bank sender IDs (e.g. HDFCBK, ICICIT, SBICRD).',
                'Credit card spend, refund and payment alerts, statements and due-date reminders.',
                'Filtering happens on the phone: OTPs, promotions and personal chats are skipped and never stored.',
              ],
            ),
            _DisclosureBlock(
              icon: AppIcons.lock,
              accent: c.success,
              title: 'What stays on your phone',
              points: const [
                'The full SMS text — it is parsed on this device and discarded.',
                'Full card numbers, CVV and expiry are never read from SMS or sent anywhere.',
              ],
            ),
            _DisclosureBlock(
              icon: AppIcons.cloudDone,
              accent: c.info,
              title: 'What we back up to your Credvert account',
              points: const [
                'Amount, currency, merchant, category, date, bank and the card\'s last 4 digits.',
                'Used only for your spend analytics, bill reminders and card milestones.',
                'Never sold, never used for ads or lending decisions.',
              ],
            ),
            _DisclosureBlock(
              icon: AppIcons.settings,
              accent: c.warning,
              title: 'You stay in control',
              points: const [
                'Pause tracking any time from Spend Insights → Settings.',
                'Delete all SMS-derived data from the device and our servers in one tap.',
                'Revoke the SMS permission in Android Settings whenever you like.',
              ],
            ),
            const SizedBox(height: AppDimensions.p8),
            Text(
              'Consent notice ${SmsConsent.currentVersion}. You can withdraw consent as easily as you gave it.',
              style: AppTypography.bodySmall.copyWith(color: c.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.p20),
            ValueListenableBuilder<bool>(
              valueListenable: context.read<_ConsentBusy>(),
              builder: (context, busy, _) => LuxuryButton(
                label: AppStrings.smsConsentCta,
                icon: AppIcons.shieldCheck,
                isLoading: busy,
                onPressed: () => _onAgree(context),
              ),
            ),
            const SizedBox(height: AppDimensions.p12),
            LuxuryButton(
              label: AppStrings.smsConsentDecline,
              variant: LuxuryButtonVariant.secondary,
              onPressed: () async {
                await context.read<ExpenseProvider>().declineConsent();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppDimensions.p24),
          ],
        ),
      ),
    );
  }

  Future<void> _onAgree(BuildContext context) async {
    final busy = context.read<_ConsentBusy>();
    final provider = context.read<ExpenseProvider>();
    busy.value = true;
    HapticsHelper.medium();
    final enabled = await provider.grantConsentAndEnable();
    busy.value = false;
    if (!context.mounted) return;

    if (enabled) {
      final found = provider.lastScan?.newTransactions ?? 0;
      AppToast.success(
        context,
        title: 'SMS tracking on',
        message: found == 0 ? 'New card alerts will appear automatically.' : 'Imported $found card transactions.',
      );
      Navigator.of(context).pop();
      return;
    }

    if (provider.permission == SmsPermissionStatus.permanentlyDenied) {
      AppToast.warning(
        context,
        title: 'Permission blocked',
        message: 'Enable SMS in Settings → Permissions to finish setup.',
      );
      await provider.openAppSettings();
    } else {
      AppToast.warning(
        context,
        title: 'Permission not granted',
        message: 'You can still paste bank SMS or add spends manually.',
      );
    }
  }
}

class _DisclosureBlock extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final List<String> points;

  const _DisclosureBlock({required this.icon, required this.accent, required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p12),
      child: LuxuryGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: AppDimensions.iconMd),
                const SizedBox(width: AppDimensions.p8),
                Text(title, style: AppTypography.titleMedium.copyWith(color: context.colors.textPrimary)),
              ],
            ),
            const SizedBox(height: AppDimensions.p8),
            for (final p in points)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.p4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.check, size: AppDimensions.iconXs, color: accent),
                    const SizedBox(width: AppDimensions.p8),
                    Expanded(child: Text(p, style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary))),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppDimensions.mediumAnim);
  }
}
