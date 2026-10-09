import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../storage/secure_vault_service.dart';
import 'context_ext.dart';
import 'haptics_helper.dart';

enum AppToastType { success, error, info, warning }

/// Compact, theme-aware floating toasts.
class AppToast {
  const AppToast._();

  static void success(BuildContext context, {required String message, String? title}) {
    HapticsHelper.success();
    _show(context, message: message, title: title, type: AppToastType.success);
  }

  static void error(BuildContext context, {required String message, String? title}) {
    HapticsHelper.error();
    _show(context, message: message, title: title, type: AppToastType.error, seconds: 5);
  }

  static void info(BuildContext context, {required String message, String? title}) {
    _show(context, message: message, title: title, type: AppToastType.info);
  }

  static void warning(BuildContext context, {required String message, String? title}) {
    HapticsHelper.medium();
    _show(context, message: message, title: title, type: AppToastType.warning);
  }

  /// Maps a vault result to the right toast. Cancelled prompts stay silent.
  static void vault(BuildContext context, VaultStatus status, {required String successMessage}) {
    switch (status) {
      case VaultStatus.success:
        success(context, message: successMessage);
      case VaultStatus.cancelled:
        break;
      case VaultStatus.notFound:
        info(context, message: status.message);
      case VaultStatus.lockedOut:
      case VaultStatus.notEnrolled:
        warning(context, message: status.message);
      case VaultStatus.error:
        error(context, message: status.message);
    }
  }

  static void _show(
    BuildContext context, {
    required String message,
    String? title,
    required AppToastType type,
    int seconds = 3,
  }) {
    final c = context.colors;
    final (Color tone, IconData icon) = switch (type) {
      AppToastType.success => (c.success, AppIcons.checkCircle),
      AppToastType.error => (c.danger, AppIcons.warning),
      AppToastType.warning => (c.warning, AppIcons.warning),
      AppToastType.info => (c.info, AppIcons.info),
    };

    toastification.dismissAll(delayForAnimation: false);
    toastification.showCustom(
      context: context,
      autoCloseDuration: Duration(seconds: seconds),
      alignment: Alignment.topCenter,
      builder: (ctx, item) => _ToastBody(
        tone: tone,
        icon: icon,
        title: title,
        message: message,
        onDismiss: () => toastification.dismiss(item),
      ),
    );
  }
}

class _ToastBody extends StatelessWidget {
  final Color tone;
  final IconData icon;
  final String? title;
  final String message;
  final VoidCallback onDismiss;

  const _ToastBody({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: AppDimensions.roundedMd,
                  border: Border.all(color: c.borderStrong),
                  boxShadow: [BoxShadow(color: c.shadow, blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: tone),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null) Text(title!, style: context.text.labelLarge),
                          Text(
                            message,
                            style: context.text.bodySmall!.copyWith(color: c.textSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
