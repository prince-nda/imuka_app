import 'package:equatable/equatable.dart';

/// Whether the account is for someone relocating or for a landlord / agent.
enum UserRole {
  mover('I am moving'),
  landlord('I am a landlord');

  const UserRole(this.label);
  final String label;
}

/// How the user signed in.
enum SignInMethod { email, google }

/// The signed-in user: Firebase Auth identity merged with the Firestore
/// profile in `users/{uid}`.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.signInMethod,
    this.email,
    this.phone = '',
    this.emailVerified = false,
  });

  final String id;
  final String fullName;
  final String? email;

  /// 9-digit local contact number (without +250); empty when unknown.
  /// Not verified — used so movers and owners can reach the user.
  final String phone;
  final UserRole role;
  final SignInMethod signInMethod;
  final bool emailVerified;

  String get firstName {
    final first = fullName.trim().split(' ').first;
    return first.isEmpty ? 'there' : first;
  }

  /// Email accounts must confirm their address before using the app.
  bool get needsEmailVerification =>
      signInMethod == SignInMethod.email && !emailVerified;

  AppUser copyWith({String? fullName, String? phone, bool? emailVerified}) =>
      AppUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        phone: phone ?? this.phone,
        role: role,
        signInMethod: signInMethod,
        emailVerified: emailVerified ?? this.emailVerified,
      );

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    role,
    signInMethod,
    emailVerified,
  ];
}
