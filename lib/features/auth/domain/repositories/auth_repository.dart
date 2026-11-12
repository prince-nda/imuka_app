import '../entities/app_user.dart';

/// Thrown by [AuthRepository] with a message that is safe to show to users.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// Authentication contract with two sign-in methods: email + password and
/// Google.
///
/// The presentation layer only depends on this interface, so the Firebase
/// implementation and the in-memory fake used in tests are interchangeable.
abstract interface class AuthRepository {
  /// Emits the signed-in user (with profile), or `null` after sign-out.
  Stream<AppUser?> get userChanges;

  /// The user restored from the last session, if any.
  AppUser? get currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  /// Creates the account and its profile, then emails a verification link.
  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  });

  Future<void> sendEmailVerification();

  /// Re-checks whether the email link was opened; returns the new status.
  Future<bool> refreshEmailVerified();

  /// Emails a password reset link.
  Future<void> sendPasswordReset(String email);

  Future<void> updateFullName(String fullName);

  Future<void> signOut();
}
