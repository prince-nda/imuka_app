import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SignupState extends Equatable {
  const SignupState({
    this.role = UserRole.mover,
    this.termsAccepted = false,
    this.showTermsError = false,
    this.passwordObscured = true,
    this.status = RequestStatus.initial,
    this.errorMessage,
  });

  final UserRole role;
  final bool termsAccepted;
  final bool showTermsError;
  final bool passwordObscured;
  final RequestStatus status;
  final String? errorMessage;

  SignupState copyWith({
    UserRole? role,
    bool? termsAccepted,
    bool? showTermsError,
    bool? passwordObscured,
    RequestStatus? status,
    String? errorMessage,
  }) => SignupState(
    role: role ?? this.role,
    termsAccepted: termsAccepted ?? this.termsAccepted,
    showTermsError: showTermsError ?? this.showTermsError,
    passwordObscured: passwordObscured ?? this.passwordObscured,
    status: status ?? this.status,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    role,
    termsAccepted,
    showTermsError,
    passwordObscured,
    status,
    errorMessage,
  ];
}

/// Registers an email account. Afterwards the router takes the user to
/// email verification.
class SignupCubit extends Cubit<SignupState> with SafeEmit<SignupState> {
  SignupCubit(this._repository) : super(const SignupState());

  final AuthRepository _repository;

  void selectRole(UserRole role) => emit(state.copyWith(role: role));

  void setTermsAccepted(bool accepted) =>
      emit(state.copyWith(termsAccepted: accepted, showTermsError: false));

  /// Shows the terms error without submitting (used when other fields are
  /// invalid, so every problem is visible at once).
  void validateTerms() {
    if (!state.termsAccepted) emit(state.copyWith(showTermsError: true));
  }

  void togglePasswordVisibility() =>
      emit(state.copyWith(passwordObscured: !state.passwordObscured));

  /// Field validation happens in the form; this guards the terms checkbox
  /// and then creates the account.
  Future<void> submit({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (state.status.isLoading) return;
    if (!state.termsAccepted) {
      emit(state.copyWith(showTermsError: true));
      return;
    }
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      await _repository.registerWithEmail(
        fullName: fullName,
        email: email,
        phone: Validators.digitsOnly(phone),
        password: password,
        role: state.role,
      );
      emit(state.copyWith(status: RequestStatus.success));
    } on AuthFailure catch (e) {
      emit(
        state.copyWith(status: RequestStatus.failure, errorMessage: e.message),
      );
    }
  }
}
