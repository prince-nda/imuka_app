import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/selectors.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/signup_cubit.dart';
import '../widgets/auth_widgets.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupCubit(context.read<AuthRepository>()),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

/// Stateful only to own the form controllers; all UI state is in
/// [SignupCubit].
class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final fieldsValid = _formKey.currentState!.validate();
    final cubit = context.read<SignupCubit>();
    if (!fieldsValid) {
      cubit.validateTerms();
      return;
    }
    cubit.submit(
      fullName: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocListener<SignupCubit, SignupState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == RequestStatus.failure) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
      },
      child: Scaffold(
        appBar: const ImukaAppBar(title: 'Create account'),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: ScrollWithFooter(
                footer: AuthSwitchLink(
                  prompt: 'Already have an account?',
                  action: 'Log in',
                  onTap: () => context.pushReplacement(AppRoutes.login),
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Join Imuka',
                      style: context.text.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 14),
                  BlocSelector<SignupCubit, SignupState, UserRole>(
                    selector: (s) => s.role,
                    builder: (context, role) => SegmentedSelector<UserRole>(
                      options: UserRole.values,
                      selected: role,
                      labelOf: (r) => r.label,
                      onChanged: context.read<SignupCubit>().selectRole,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 16, color: p.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Landlords and agents confirm their National ID '
                          'before listing.',
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const FieldLabel('Full name'),
                  AppTextField(
                    controller: _name,
                    hint: 'Aline Uwase',
                    prefixIcon: LucideIcons.user,
                    validator: Validators.fullName,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                  ),
                  const FieldLabel('Email'),
                  AppTextField(
                    controller: _email,
                    hint: 'you@example.com',
                    prefixIcon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const FieldLabel('Phone number'),
                  PhoneField(controller: _phone),
                  const FieldLabel('Create a password'),
                  BlocSelector<SignupCubit, SignupState, bool>(
                    selector: (s) => s.passwordObscured,
                    builder: (context, obscured) => PasswordField(
                      controller: _password,
                      obscured: obscured,
                      isNewPassword: true,
                      hint: '8+ characters, letters and numbers',
                      validator: Validators.password,
                      onToggleVisibility: context
                          .read<SignupCubit>()
                          .togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _TermsCheckbox(),
                  const SizedBox(height: 12),
                  BlocSelector<SignupCubit, SignupState, bool>(
                    selector: (s) => s.status.isLoading,
                    builder: (context, loading) => PrimaryButton(
                      label: 'Create account',
                      isLoading: loading,
                      onPressed: _submit,
                    ),
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

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<SignupCubit, SignupState>(
      buildWhen: (a, b) =>
          a.termsAccepted != b.termsAccepted ||
          a.showTermsError != b.showTermsError,
      builder: (context, state) {
        final cubit = context.read<SignupCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => cubit.setTermsAccepted(!state.termsAccepted),
                child: Row(
                  children: [
                    Checkbox(
                      value: state.termsAccepted,
                      onChanged: (v) => cubit.setTermsAccepted(v ?? false),
                      side: BorderSide(
                        color: state.showTermsError
                            ? p.danger
                            : p.textSecondary,
                        width: 1.5,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the Terms and Privacy Policy',
                        style: context.text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.showTermsError)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  'Please accept the Terms and Privacy Policy to continue.',
                  style: context.text.bodySmall?.copyWith(color: p.danger),
                ),
              ),
          ],
        );
      },
    );
  }
}
