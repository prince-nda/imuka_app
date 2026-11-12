import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/repositories/auth_repository.dart';

/// Which button started the current request, so only it shows a spinner.
enum LoginAction { email, google }

class LoginState extends Equatable {
  const LoginState({
    this.passwordObscured = true,
    this.status = RequestStatus.initial,
    this.action,
    this.errorMessage,
  });

  final bool passwordObscured;
  final RequestStatus status;
  final LoginAction? action;
  final String? errorMessage;

  bool isLoading(LoginAction a) => status.isLoading && action == a;

  LoginState copyWith({
    bool? passwordObscured,
    RequestStatus? status,
    LoginAction? action,
    String? errorMessage,
  }) => LoginState(
    passwordObscured: passwordObscured ?? this.passwordObscured,
    status: status ?? this.status,
    action: action ?? this.action,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [passwordObscured, status, action, errorMessage];
}

/// Drives both sign-in methods. Successful sign-ins are picked up by
/// [AuthCubit] and the router, which then leaves the login screens.
class LoginCubit extends Cubit<LoginState> with SafeEmit<LoginState> {
  LoginCubit(this._repository) : super(const LoginState());

  final AuthRepository _repository;

  void togglePasswordVisibility() =>
      emit(state.copyWith(passwordObscured: !state.passwordObscured));

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _run(
    LoginAction.email,
    () => _repository.signInWithEmail(email: email, password: password),
  );

  Future<void> signInWithGoogle() =>
      _run(LoginAction.google, _repository.signInWithGoogle);

  Future<void> _run(LoginAction action, Future<void> Function() request) async {
    if (state.status.isLoading) return;
    emit(state.copyWith(status: RequestStatus.loading, action: action));
    try {
      await request();
      emit(state.copyWith(status: RequestStatus.success));
    } on AuthFailure catch (e) {
      emit(
        state.copyWith(status: RequestStatus.failure, errorMessage: e.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          errorMessage:
              'Something went wrong. Check your connection and try again.',
        ),
      );
    }
  }
}
