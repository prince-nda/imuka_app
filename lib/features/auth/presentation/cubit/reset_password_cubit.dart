import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/repositories/auth_repository.dart';

typedef ResetPasswordState = ({RequestStatus status, String? errorMessage});

/// Sends a password reset email.
class ResetPasswordCubit extends Cubit<ResetPasswordState>
    with SafeEmit<ResetPasswordState> {
  ResetPasswordCubit(this._repository)
    : super((status: RequestStatus.initial, errorMessage: null));

  final AuthRepository _repository;

  Future<void> sendReset(String email) async {
    if (state.status.isLoading) return;
    emit((status: RequestStatus.loading, errorMessage: null));
    try {
      await _repository.sendPasswordReset(email);
      emit((status: RequestStatus.success, errorMessage: null));
    } on AuthFailure catch (e) {
      emit((status: RequestStatus.failure, errorMessage: e.message));
    }
  }
}
