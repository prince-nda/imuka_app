import 'dart:async';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository] used by tests and by offline demo builds
/// (`--dart-define=USE_MOCKS=true`).
///
/// Demo account: `aline@imuka.rw` / `demo-password-123`.
/// New accounts start with an unverified email; call [confirmEmail] to
/// simulate opening the verification link.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 600)});

  static const demoEmail = 'aline@imuka.rw';
  static const demoPassword = 'demo-password-123';

  final Duration latency;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;
  int _counter = 0;

  final Map<String, ({AppUser user, String password})> _byEmail = {
    demoEmail: (
      user: const AppUser(
        id: 'user-aline',
        fullName: 'Aline Uwase',
        email: demoEmail,
        phone: '788123456',
        role: UserRole.mover,
        signInMethod: SignInMethod.email,
        emailVerified: true,
      ),
      password: demoPassword,
    ),
  };

  /// Emails sent, for assertions in tests.
  final List<String> sentEmails = [];

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  AppUser? get currentUser => _current;

  void _emit(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  Future<void> _wait() => Future<void>.delayed(latency);

  /// Simulates the user opening the email verification link.
  void confirmEmail() {
    final user = _current;
    if (user == null) return;
    final updated = user.copyWith(emailVerified: true);
    _byEmail[user.email!] = (
      user: updated,
      password: _byEmail[user.email!]!.password,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _wait();
    final account = _byEmail[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthFailure('Email or password is incorrect.');
    }
    _emit(account.user);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _wait();
    _emit(
      const AppUser(
        id: 'user-google',
        fullName: 'Aline Uwase',
        email: 'aline.uwase@gmail.com',
        role: UserRole.mover,
        signInMethod: SignInMethod.google,
        emailVerified: true,
      ),
    );
  }

  @override
  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    await _wait();
    final key = email.trim().toLowerCase();
    if (_byEmail.containsKey(key)) {
      throw const AuthFailure(
        'An account already uses this email. Log in instead.',
      );
    }
    final user = AppUser(
      id: 'user-${++_counter}',
      fullName: fullName.trim(),
      email: key,
      phone: phone,
      role: role,
      signInMethod: SignInMethod.email,
    );
    _byEmail[key] = (user: user, password: password);
    sentEmails.add('verify:$key');
    _emit(user);
  }

  @override
  Future<void> sendEmailVerification() async {
    await _wait();
    sentEmails.add('verify:${_current?.email}');
  }

  @override
  Future<bool> refreshEmailVerified() async {
    await _wait();
    final email = _current?.email;
    if (email == null) return false;
    final stored = _byEmail[email]?.user;
    if (stored != null && stored.emailVerified) {
      _updateCurrent((u) => u.copyWith(emailVerified: true));
    }
    return _current?.emailVerified ?? false;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _wait();
    sentEmails.add('reset:${email.trim().toLowerCase()}');
  }

  @override
  Future<void> updateFullName(String fullName) async {
    await _wait();
    _updateCurrent((u) => u.copyWith(fullName: fullName.trim()));
  }

  @override
  Future<void> signOut() async => _emit(null);

  void _updateCurrent(AppUser Function(AppUser) update) {
    final user = _current;
    if (user == null) return;
    final updated = update(user);
    final email = updated.email;
    if (email != null && _byEmail.containsKey(email)) {
      _byEmail[email] = (user: updated, password: _byEmail[email]!.password);
    }
    _emit(updated);
  }
}
