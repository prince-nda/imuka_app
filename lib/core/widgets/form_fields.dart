import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../utils/validators.dart';

/// Text input styled like the Figma fields (sand fill, rounded, icon prefix).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.hint,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.semanticLabel,
  });

  final TextEditingController controller;

  /// Lets a page validate this single field on its own.
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final String? hint;
  final IconData? prefixIcon;

  /// Custom prefix widget; wins over [prefixIcon].
  final Widget? prefix;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      key: fieldKey,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLines: maxLines,
      onFieldSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            prefix ??
            (prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 20,
                    color: context.palette.textPrimary,
                  )),
        prefixIconConstraints: const BoxConstraints(
          minHeight: 48,
          minWidth: 48,
        ),
        suffixIcon: suffix,
      ),
    );
    if (semanticLabel == null) return field;
    return Semantics(label: semanticLabel, child: field);
  }
}

/// Phone input with the "RW +250" prefix chip.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.validator = Validators.phone,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppTextField(
      controller: controller,
      fieldKey: fieldKey,
      validator: validator,
      hint: '788 123 456',
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
        LengthLimitingTextInputFormatter(11),
      ],
      semanticLabel: 'Phone number, Rwanda plus 250',
      prefix: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'RW  +250',
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Password field with a show-hide eye toggle.
///
/// Visibility is owned by the caller's Cubit, keeping this widget stateless.
class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.obscured,
    required this.onToggleVisibility,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.hint = 'Password',
    this.isNewPassword = false,
  });

  final TextEditingController controller;
  final bool obscured;
  final String hint;

  /// Uses the "new password" autofill hint (sign-up).
  final bool isNewPassword;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      validator: validator,
      obscureText: obscured,
      prefixIcon: LucideIcons.lock,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: [
        isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      hint: hint,
      suffix: IconButton(
        tooltip: obscured ? 'Show password' : 'Hide password',
        onPressed: onToggleVisibility,
        icon: Icon(
          obscured ? LucideIcons.eye : LucideIcons.eyeOff,
          size: 20,
          color: context.palette.textSecondary,
        ),
      ),
    );
  }
}
