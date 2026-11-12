import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/repositories/auth_repository.dart';

class VerifyEmailState extends Equatable {
  const VerifyEmailState({
    this.checkStatus = RequestStatus.initial,
    this.resendCooldown = 0,
    this.message,
    this.isError = false,
  });

  final RequestStatus checkStatus;

  /// Seconds before another verification email can be sent.
  final int resendCooldown;

  /// One-off feedback for a snackbar.
  final String? message;
  final bool isError;

  @override
  List<Object?> get props => [checkStatus, resendCooldown, message, isError];
}

/// "Check your inbox" screen: resend the link or confirm it was opened.
class VerifyEmailCubit extends Cubit<VerifyEmailState>
    with SafeEmit<VerifyEmailState> {
  VerifyEmailCubit(this._repository) : super(const VerifyEmailState()) {
    _startCooldown();
  }

  static const cooldownSeconds = 30;

  final AuthRepository _repository;
  Timer? _timer;

  /// When verified, [AuthCubit] gets the update and the router continues.
  Future<void> checkVerified() async {
    if (state.checkStatus.isLoading) return;
    emit(_copy(checkStatus: RequestStatus.loading));
    try {
      final verified = await _repository.refreshEmailVerified();
      emit(
        _copy(
          checkStatus: verified ? RequestStatus.success : RequestStatus.failure,
          message: verified
              ? null
              : 'Not verified yet. Open the link in the email, then try '
                    'again.',
          isError: !verified,
        ),
      );
    } on AuthFailure catch (e) {
      emit(
        _copy(
          checkStatus: RequestStatus.failure,
          message: e.message,
          isError: true,
        ),
      );
    }
  }

  Future<void> resend() async {
    if (state.resendCooldown > 0) return;
    try {
      await _repository.sendEmailVerification();
      emit(_copy(message: 'We sent you a new link.'));
      _startCooldown();
    } on AuthFailure catch (e) {
      emit(_copy(message: e.message, isError: true));
    }
  }

  VerifyEmailState _copy({
    RequestStatus? checkStatus,
    int? resendCooldown,
    String? message,
    bool isError = false,
  }) => VerifyEmailState(
    checkStatus: checkStatus ?? state.checkStatus,
    resendCooldown: resendCooldown ?? state.resendCooldown,
    message: message,
    isError: isError,
  );

  void _startCooldown() {
    _timer?.cancel();
    emit(_copy(resendCooldown: cooldownSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendCooldown - 1;
      emit(_copy(resendCooldown: next < 0 ? 0 : next));
      if (next <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
