import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/theme/app_theme.dart';
import 'package:imuka/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:imuka/features/auth/domain/repositories/auth_repository.dart';
import 'package:imuka/features/auth/presentation/cubit/auth_cubit.dart';

/// Pumps [child] inside the Imuka theme with an [AuthRepository] and
/// [AuthCubit] available, and returns the repository for assertions.
Future<MockAuthRepository> pumpWithAuth(
  WidgetTester tester,
  Widget child,
) async {
  final auth = MockAuthRepository(latency: Duration.zero);
  await tester.pumpWidget(
    RepositoryProvider<AuthRepository>.value(
      value: auth,
      child: BlocProvider(
        create: (_) => AuthCubit(auth),
        child: MaterialApp(theme: AppTheme.light, home: child),
      ),
    ),
  );
  return auth;
}

/// Wraps a widget in the app theme only.
Widget themed(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);
