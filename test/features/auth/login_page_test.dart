import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:imuka/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:imuka/features/auth/presentation/pages/login_page.dart';

import '../../helpers/pump_app.dart';

void main() {
  Finder field(int index) => find.byType(TextFormField).at(index);

  testWidgets('shows polite validation messages for empty fields', (
    tester,
  ) async {
    await pumpWithAuth(tester, const LoginPage());

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please fill in your password.'), findsOneWidget);
  });

  testWidgets('rejects a malformed email before calling the server', (
    tester,
  ) async {
    final auth = await pumpWithAuth(tester, const LoginPage());

    await tester.enterText(field(0), 'aline.imuka.rw');
    await tester.enterText(field(1), 'kigali2026');
    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(
      find.text('That email address doesn\'t look right.'),
      findsOneWidget,
    );
    expect(auth.currentUser, isNull);
  });

  testWidgets('the password visibility toggle is driven by the cubit', (
    tester,
  ) async {
    await pumpWithAuth(tester, const LoginPage());
    EditableText password() => tester.widget<EditableText>(
      find.descendant(of: field(1), matching: find.byType(EditableText)),
    );

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('valid credentials sign the user in', (tester) async {
    await pumpWithAuth(tester, const LoginPage());

    await tester.enterText(field(0), MockAuthRepository.demoEmail);
    await tester.enterText(field(1), MockAuthRepository.demoPassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LoginPage));
    expect(context.read<AuthCubit>().state.isAuthenticated, isTrue);
  });

  testWidgets('a wrong password shows the error in a snackbar', (tester) async {
    await pumpWithAuth(tester, const LoginPage());

    await tester.enterText(field(0), MockAuthRepository.demoEmail);
    await tester.enterText(field(1), 'wrong-pass1');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });
}
