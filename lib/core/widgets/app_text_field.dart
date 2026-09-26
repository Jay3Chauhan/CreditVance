import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/context_ext.dart';

/// Labelled text input built on the themed [InputDecorationTheme].
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool enabled;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextStyle? style;

  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofillHints,
    this.autofocus = false,
    this.enabled = true,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: context.text.labelMedium),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autofillHints: autofillHints,
          autofocus: autofocus,
          enabled: enabled,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: style ?? context.text.bodyLarge!.copyWith(color: c.textPrimary),
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            errorText: errorText,
            counterText: '',
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18, color: c.textTertiary),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
