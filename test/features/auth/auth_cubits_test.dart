import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/utils/request_status.dart';
import 'package:imuka/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:imuka/features/auth/domain/entities/app_user.dart';
import 'package:imuka/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:imuka/features/auth/presentation/cubit/login_cubit.dart';
import 'package:imuka/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:imuka/features/auth/presentation/cubit/signup_cubit.dart';
import 'package:imuka/features/auth/presentation/cubit/verify_email_cubit.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository(latency: Duration.zero));

  group('email + password', () {
    blocTest<LoginCubit, LoginState>(
      'a wrong password shows a specific error',
      build: () => LoginCubit(repository),
      act: (cubit) => cubit.signInWithEmail(
        email: MockAuthRepository.demoEmail,
        password: 'wrong-pass1',
      ),
      verify: (cubit) {
        expect(cubit.state.status, RequestStatus.failure);
        expect(cubit.state.errorMessage, 'Email or password is incorrect.');
        expect(repository.currentUser, isNull);
      },
    );

    test('signing in and out updates the session', () async {
      final auth = AuthCubit(repository);
      await LoginCubit(repository).signInWithEmail(
        email: 'Aline@Imuka.rw',
        password: MockAuthRepository.demoPassword,
      );
      await pumpEventQueue();
      expect(auth.state.isAuthenticated, isTrue);
      expect(auth.state.user?.firstName, 'Aline');

      await auth.signOut();
      await pumpEventQueue();
      expect(auth.state.isAuthenticated, isFalse);
      await auth.close();
    });
  });

  group('sign-up', () {
    blocTest<SignupCubit, SignupState>(
      'is blocked until the terms are accepted',
      build: () => SignupCubit(repository),
      act: (cubit) => cubit.submit(
        fullName: 'Eric Mugisha',
        email: 'eric@imuka.rw',
        phone: '782000111',
        password: 'demo-password-123',
      ),
      expect: () => [const SignupState(showTermsError: true)],
    );

    test('creates an account that must verify its email', () async {
      final signup = SignupCubit(repository)
        ..selectRole(UserRole.landlord)
        ..setTermsAccepted(true);
      await signup.submit(
        fullName: 'Eric Mugisha',
        email: 'eric@imuka.rw',
        phone: '782 000 111',
        password: 'demo-password-123',
      );
      final user = repository.currentUser!;
      expect(user.role, UserRole.landlord);
      expect(user.phone, '782000111', reason: 'kept as a contact number');
      expect(user.needsEmailVerification, isTrue);
      expect(repository.sentEmails, contains('verify:eric@imuka.rw'));

      // Not verified until the link in the email is opened.
      final verifyEmail = VerifyEmailCubit(repository);
      await verifyEmail.checkVerified();
      expect(verifyEmail.state.isError, isTrue);
      repository.confirmEmail();
      await verifyEmail.checkVerified();
      expect(repository.currentUser!.needsEmailVerification, isFalse);
      await verifyEmail.close();
    });
  });

  test('Google accounts are verified straight away', () async {
    await LoginCubit(repository).signInWithGoogle();
    final user = repository.currentUser!;
    expect(user.signInMethod, SignInMethod.google);
    expect(user.needsEmailVerification, isFalse);
  });

  blocTest<ResetPasswordCubit, ResetPasswordState>(
    'password reset emails a link',
    build: () => ResetPasswordCubit(repository),
    act: (cubit) => cubit.sendReset(' Aline@Imuka.rw '),
    expect: () => [
      (status: RequestStatus.loading, errorMessage: null),
      (status: RequestStatus.success, errorMessage: null),
    ],
    verify: (_) =>
        expect(repository.sentEmails, contains('reset:aline@imuka.rw')),
  );
}
