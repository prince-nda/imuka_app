import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/data/firestore_paths.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication, with the user
/// profile stored in Firestore at `users/{uid}`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _google = googleSignIn ?? GoogleSignIn.instance {
    _subscription = _auth.userChanges().asyncMap(_toAppUser).listen((user) {
      _current = user;
      _controller.add(user);
      if (!_ready.isCompleted) _ready.complete();
    }, onError: _controller.addError);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;
  final _controller = StreamController<AppUser?>.broadcast();
  final _ready = Completer<void>();
  late final StreamSubscription<AppUser?> _subscription;
  AppUser? _current;
  bool _googleInitialized = false;

  /// Profile to write for an account that is being registered right now
  /// (Firebase reports the new user before the profile is saved).
  Map<String, Object?>? _pendingProfile;

  /// Completes once the saved session has been restored on app start.
  Future<void> get ready => _ready.future;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  AppUser? get currentUser => _current;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _db.doc(FirestorePaths.user(uid));

  // ---------------------------------------------------------------------
  // Email + password
  // ---------------------------------------------------------------------

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) => _guard(() async {
    _pendingProfile = {
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone,
      'role': role.name,
    };
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await _writeProfile(user.uid, _pendingProfile!);
      await user.updateDisplayName(fullName.trim());
      await user.sendEmailVerification();
      await _emitFresh();
    } finally {
      _pendingProfile = null;
    }
  });

  @override
  Future<void> sendEmailVerification() => _guard(() async {
    await _auth.currentUser?.sendEmailVerification();
  });

  @override
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await _guard(user.reload);
    if (_auth.currentUser?.emailVerified ?? false) {
      // Refresh the ID token so security rules see `email_verified: true`.
      await _auth.currentUser!.getIdToken(true);
    }
    await _emitFresh();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  // ---------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    if (!_googleInitialized) {
      await _google.initialize();
      _googleInitialized = true;
    }
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailure('Google didn\'t return a sign-in token.');
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  });

  // ---------------------------------------------------------------------
  // Profile & session
  // ---------------------------------------------------------------------

  @override
  Future<void> updateFullName(String fullName) async {
    await _updateProfile({'fullName': fullName.trim()});
    await _auth.currentUser?.updateDisplayName(fullName.trim());
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Not signed in with Google; nothing to clear.
    }
    await _auth.signOut();
  }

  Future<void> _updateProfile(Map<String, Object?> data) => _guard(() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthFailure('Please log in again.');
    await _profileRef(uid)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    await _emitFresh();
  });

  Future<void> _writeProfile(String uid, Map<String, Object?> data) =>
      _profileRef(uid).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Re-reads the profile and pushes it to listeners (profile changes in
  /// Firestore don't trigger [FirebaseAuth.userChanges]).
  Future<void> _emitFresh() async {
    final user = await _toAppUser(_auth.currentUser);
    _current = user;
    _controller.add(user);
  }

  /// Merges the Firebase user with its Firestore profile, creating the
  /// profile on first Google sign-in.
  Future<AppUser?> _toAppUser(User? user) async {
    if (user == null) return null;
    final ref = _profileRef(user.uid);
    var snapshot = await ref.get();
    final pending = _pendingProfile;
    if (!snapshot.exists && pending != null) {
      // Sign-up in progress: registerWithEmail writes the profile itself
      // (a second write would be rejected by the security rules).
      return _fromProfile(user, pending);
    }
    if (!snapshot.exists) {
      await _writeProfile(user.uid, {
        'fullName': user.displayName ?? '',
        'email': user.email?.toLowerCase(),
        'phone': '',
        'role': UserRole.mover.name,
      });
      snapshot = await ref.get();
    }
    return _fromProfile(user, snapshot.data() ?? const {});
  }

  AppUser _fromProfile(User user, Map<String, Object?> data) {
    final providers = user.providerData.map((p) => p.providerId).toSet();
    final method = providers.contains('password')
        ? SignInMethod.email
        : SignInMethod.google;
    return AppUser(
      id: user.uid,
      fullName: data['fullName'] as String? ?? user.displayName ?? '',
      email: user.email ?? data['email'] as String?,
      phone: data['phone'] as String? ?? '',
      role: UserRole.values.asNameMap()[data['role']] ?? UserRole.mover,
      signInMethod: method,
      emailVerified: user.emailVerified,
    );
  }

  /// Runs [action] and converts Firebase errors into [AuthFailure]s.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw _map(e);
    }
  }

  static AuthFailure _map(Object error) {
    if (error is AuthFailure) return error;
    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.canceled
          ? const AuthFailure('Google sign-in was cancelled.')
          : const AuthFailure('Google sign-in failed. Please try again.');
    }
    if (error is FirebaseAuthException) {
      return AuthFailure(switch (error.code) {
        'invalid-email' => 'That email address doesn\'t look right.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => 'Email or password is incorrect.',
        'email-already-in-use' =>
          'An account already uses this email. Log in instead.',
        'weak-password' => 'Choose a stronger password (8+ characters).',
        'too-many-requests' =>
          'Too many attempts. Please wait a moment and try again.',
        'network-request-failed' =>
          'No internet connection. Check your network and try again.',
        'account-exists-with-different-credential' =>
          'This email already has an Imuka account. Log in with your '
              'password instead.',
        'requires-recent-login' => 'Please log in again to continue.',
        'operation-not-allowed' =>
          'This sign-in method isn\'t enabled yet. Please use another one.',
        _ => error.message ?? 'Something went wrong. Please try again.',
      });
    }
    if (error is FirebaseException) {
      return AuthFailure(
        error.code == 'unavailable'
            ? 'No internet connection. Check your network and try again.'
            : 'We couldn\'t save your profile. Please try again.',
      );
    }
    return const AuthFailure('Something went wrong. Please try again.');
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
