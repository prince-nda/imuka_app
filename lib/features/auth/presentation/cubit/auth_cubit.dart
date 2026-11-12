import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._(this.status, this.user);

  const AuthState.authenticated(AppUser user)
    : this._(AuthStatus.authenticated, user);

  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [status, user];
}

/// App-wide session state. The router listens to it to guard screens.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository)
    : super(
        _repository.currentUser == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(_repository.currentUser!),
      ) {
    _subscription = _repository.userChanges.listen(
      (user) => emit(
        user == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(user),
      ),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  Future<void> signOut() => _repository.signOut();

  /// Updates the profile name; returns an error message on failure.
  Future<String?> updateFullName(String fullName) async {
    try {
      await _repository.updateFullName(fullName);
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
