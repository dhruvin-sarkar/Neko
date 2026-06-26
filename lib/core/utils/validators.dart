/// Pure input validators. Each returns `null` when valid, or a user-facing
/// message when invalid, matching the `TextFormField` validator contract.
abstract final class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  static String? email(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!_email.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'At least 8 characters';
    return null;
  }

  /// Sign-in only needs a non-empty password. The 8-character policy is a
  /// registration rule — enforcing it on the login form would lock out valid
  /// accounts whose password is shorter (Firebase's own minimum is 6, and
  /// accounts may have been created outside this app). Let Firebase decide if
  /// the password is correct.
  static String? signInPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? catName(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Your cat needs a name';
    if (text.length > 50) return 'Keep it under 50 characters';
    return null;
  }
}
