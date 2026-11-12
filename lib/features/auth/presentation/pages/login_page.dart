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
import '../../domain/repositories/auth_repository.dart';
import '../cubit/login_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Log in with email + password, or with Google.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(context.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

/// Stateful only to own the form controllers; all UI state is in
/// [LoginCubit].
class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _logIn() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginCubit>().signInWithEmail(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == RequestStatus.failure) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
      },
      child: Scaffold(
        appBar: const ImukaAppBar(),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: ScrollWithFooter(
                footer: AuthSwitchLink(
                  prompt: 'New to Imuka?',
                  action: 'Create account',
                  onTap: () => context.pushReplacement(AppRoutes.signup),
                ),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ImukaLogo(size: 44),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      'Welcome back',
                      style: context.text.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log in to keep planning your move to Kigali.',
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
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const FieldLabel('Password'),
                  BlocSelector<LoginCubit, LoginState, bool>(
                    selector: (s) => s.passwordObscured,
                    builder: (context, obscured) => PasswordField(
                      controller: _password,
                      obscured: obscured,
                      validator: (v) =>
                          Validators.required(v, field: 'your password'),
                      onToggleVisibility: context
                          .read<LoginCubit>()
                          .togglePasswordVisibility,
                      onSubmitted: (_) => _logIn(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.resetPassword),
                      child: Text(
                        'Forgot password?',
                        style: context.text.titleSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  BlocBuilder<LoginCubit, LoginState>(
                    builder: (context, state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryButton(
                          label: 'Log in',
                          isLoading: state.isLoading(LoginAction.email),
                          onPressed: _logIn,
                        ),
                        const SizedBox(height: 20),
                        const LabeledDivider('or continue with'),
                        const SizedBox(height: 20),
                        OutlineAppButton(
                          label: state.isLoading(LoginAction.google)
                              ? 'Connecting…'
                              : 'Continue with Google',
                          leading: const GoogleMark(),
                          onPressed: context
                              .read<LoginCubit>()
                              .signInWithGoogle,
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
    );
  }
}
