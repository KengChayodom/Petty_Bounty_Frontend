/// Pure, UI-free form validators for the auth screens (Feature #1).
///
/// Extracted out of RegisterScreen / LoginScreen so the validation rules are
/// genuinely unit-testable (the `test` package, no widget tree) rather than only
/// reachable through a widget test. Each method has the standard Flutter
/// validator signature `String? Function(String?)` — it returns the error
/// message for the first failing rule, or null when the field is valid.
class AuthValidators {
  AuthValidators._();

  /// Real email validation (SRS-04) — replaces the old `contains('@')` check.
  static final RegExp emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Username is required (SRS-02 umbrella).
  static String? username(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Enter a username' : null;

  /// Email required (SRS-03) + well-formed (SRS-04).
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required!';
    if (!emailPattern.hasMatch(v.trim())) return 'Invalid email format';
    return null;
  }

  /// Sign-up password must be at least 6 characters (SRS-05).
  static String? password(String? v) =>
      (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null;

  /// Confirm password must equal the original password (SRS-06).
  static String? confirmPassword(String? v, String original) =>
      (v != original) ? 'Passwords must match' : null;

  /// Login password is required (SRS-02 umbrella). Unlike sign-up there is no
  /// length rule here — login just needs a non-empty value to attempt auth.
  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Enter your password' : null;
}
