import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/reset_password_cubit.dart';

/// "Forgot password?" flow: emails a password reset link.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResetPasswordCubit(context.read<AuthRepository>()),
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

/// Stateful only to own the form controller.
class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<ResetPasswordCubit>().sendReset(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        if (state.status == RequestStatus.failure) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        final sent = state.status == RequestStatus.success;
        return Scaffold(
          appBar: const ImukaAppBar(title: 'Reset password'),
          body: SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: ScrollWithFooter(
                footer: sent
                    ? PrimaryButton(
                        label: 'Back to log in',
                        onPressed: () => context.pop(),
                      )
                    : PrimaryButton(
                        label: 'Send reset link',
                        isLoading: state.status.isLoading,
                        onPressed: _submit,
                      ),
                children: sent
                    ? [
                        const SizedBox(height: 32),
                        const Center(child: SuccessCheck()),
                        const SizedBox(height: 20),
                        Text(
                          'Check your email',
                          textAlign: TextAlign.center,
                          style: context.text.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If an account exists for ${_email.text.trim()}, '
                          'you\'ll get a link to set a new password.',
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ]
                    : [
                        Text(
                          'Forgot your password?',
                          style: context.text.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter the email on your account and we\'ll send '
                          'you a secure link to set a new password.',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        const FieldLabel('Email'),
                        AppTextField(
                          controller: _email,
                          hint: 'you@example.com',
                          prefixIcon: LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                          onSubmitted: (_) => _submit(),
                        ),
                      ],
              ),
            ),
          ),
        );
      },
    );
  }
}
