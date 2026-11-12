import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/router/app_router.dart';
import 'package:imuka/core/router/app_routes.dart';
import 'package:imuka/features/auth/domain/entities/app_user.dart';
import 'package:imuka/features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  const signedOut = AuthState.unauthenticated();
  const ready = AppUser(
    id: 'u1',
    fullName: 'Aline Uwase',
    email: 'aline@imuka.rw',
    phone: '788123456',
    role: UserRole.mover,
    signInMethod: SignInMethod.email,
    emailVerified: true,
  );

  test('signed-out users only reach the authentication screens', () {
    expect(authRedirect(signedOut, AppRoutes.home), AppRoutes.welcome);
    expect(authRedirect(signedOut, AppRoutes.move), AppRoutes.welcome);
    expect(authRedirect(signedOut, AppRoutes.login), isNull);
    expect(authRedirect(signedOut, AppRoutes.signup), isNull);
  });

  test('new email accounts must verify their email first', () {
    final unverified = AuthState.authenticated(
      ready.copyWith(emailVerified: false),
    );
    expect(authRedirect(unverified, AppRoutes.home), AppRoutes.verifyEmail);
    expect(authRedirect(unverified, AppRoutes.move), AppRoutes.verifyEmail);
    expect(authRedirect(unverified, AppRoutes.verifyEmail), isNull);
  });

  test('verified users skip the auth screens and reach the app', () {
    const state = AuthState.authenticated(ready);
    expect(authRedirect(state, AppRoutes.login), AppRoutes.home);
    expect(authRedirect(state, AppRoutes.verifyEmail), AppRoutes.home);
    expect(authRedirect(state, AppRoutes.shortlist), isNull);
  });

  test('Google accounts are already verified', () {
    const google = AuthState.authenticated(
      AppUser(
        id: 'g1',
        fullName: 'Aline Uwase',
        email: 'aline@gmail.com',
        role: UserRole.mover,
        signInMethod: SignInMethod.google,
        emailVerified: true,
      ),
    );
    expect(authRedirect(google, AppRoutes.move), isNull);
  });
}
