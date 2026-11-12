import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/verify_email_cubit.dart';

/// Shown to email accounts until they open the verification link.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.select((AuthCubit c) => c.state.user?.email ?? '');
    return BlocProvider(
      create: (context) => VerifyEmailCubit(context.read<AuthRepository>()),
      child: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
        listenWhen: (a, b) => b.message != null,
        listener: (context, state) =>
            showAppSnackBar(context, state.message!, isError: state.isError),
        builder: (context, state) {
          final cubit = context.read<VerifyEmailCubit>();
          final p = context.palette;
          return Scaffold(
            appBar: const ImukaAppBar(title: 'Verify email', showBack: false),
            body: SafeArea(
              top: false,
              child: ScrollWithFooter(
                footer: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      label: 'I\'ve verified my email',
                      isLoading: state.checkStatus.isLoading,
                      onPressed: cubit.checkVerified,
                    ),
                    const SizedBox(height: 4),
                    LinkButton(
                      label: state.resendCooldown > 0
                          ? 'Resend email in ${state.resendCooldown}s'
                          : 'Resend email',
                      onPressed: state.resendCooldown > 0 ? null : cubit.resend,
                    ),
                  ],
                ),
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: p.ink,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.mailCheck, color: p.onInk),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Check your inbox',
                    textAlign: TextAlign.center,
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to\n$email\n\nOpen it to '
                    'confirm your email, then come back here.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const InfoPanel(
                    icon: LucideIcons.info,
                    message:
                        'Can\'t find it? Check your spam folder. Verified '
                        'emails keep your account and payments safe.',
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: context.read<AuthCubit>().signOut,
                      child: Text(
                        'Use a different account',
                        style: context.text.labelMedium?.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
