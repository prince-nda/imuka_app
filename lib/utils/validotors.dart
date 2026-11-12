/// Form validators. Each returns `null` when the value is valid, or a polite,
/// specific message that can be shown under the field.
abstract final class Validators {
  /// Rwandan mobile numbers: 9 digits after +250, starting with 72, 73, 78
  /// or 79 (Airtel and MTN ranges).
  static final _rwandaMobile = RegExp(r'^7[2389]\d{7}$');

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String? phone(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) return 'Please enter your phone number.';
    if (digits.length != 9) {
      return 'Enter the 9 digits after +250, e.g. 788 123 456.';
    }
    if (!_rwandaMobile.hasMatch(digits)) {
      return 'That doesn\'t look like an MTN or Airtel number.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Please enter your full name.';
    if (name.length < 3) return 'Your name looks too short.';
    if (!RegExp(r"^[A-Za-zÀ-ÿ' .-]+$").hasMatch(name)) {
      return 'Use letters only for your name.';
    }
    if (!name.contains(' ')) return 'Please add your first and last name.';
    return null;
  }

  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email address.';
    if (!_email.hasMatch(v)) return 'That email address doesn\'t look right.';
    return null;
  }

  /// Passwords need 8+ characters with at least one letter and one number.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please create a password.';
    if (v.length < 8) return 'Use at least 8 characters.';
    if (!RegExp('[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use both letters and numbers in your password.';
    }
    return null;
  }

  /// Login only checks presence: strength rules apply at sign-up.
  static String? required(String? value, {String field = 'this field'}) {
    if ((value ?? '').trim().isEmpty) return 'Please fill in $field.';
    return null;
  }

  static String? itemName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Type the name of the item first.';
    if (v.length > 40) return 'Keep item names under 40 characters.';
    return null;
  }
}