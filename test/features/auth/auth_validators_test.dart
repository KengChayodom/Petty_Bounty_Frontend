// Unit tests for AuthValidators (pure functions — no widget tree, `test` package).
//
// These are true unit tests per the Flutter taxonomy: each exercises a single
// validator function in isolation. One UTC per validator method (UTC-22…26,
// continuing the backend UTC-01–21 sequence — "one method = one UTC").
//
//   UTC-22  AuthValidators.username        (MD-27, SRS-02 umbrella)
//   UTC-23  AuthValidators.email           (MD-28, SRS-03/04)
//   UTC-24  AuthValidators.password        (MD-29, SRS-05)
//   UTC-25  AuthValidators.confirmPassword (MD-30, SRS-06)
//   UTC-26  AuthValidators.loginPassword   (MD-31, SRS-02 umbrella)

import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/auth/domain/auth_validators.dart';

void main() {
  group('UTC-22 AuthValidators.username', () {
    test('TC-01 null / empty / whitespace -> "Enter a username"', () {
      expect(AuthValidators.username(null), 'Enter a username');
      expect(AuthValidators.username(''), 'Enter a username');
      expect(AuthValidators.username('   '), 'Enter a username');
    });
    test('TC-02 non-empty -> null', () {
      expect(AuthValidators.username('Chaiudom'), isNull);
    });
  });

  group('UTC-23 AuthValidators.email', () {
    test('TC-01 null / empty -> "Email is required!"', () {
      expect(AuthValidators.email(null), 'Email is required!');
      expect(AuthValidators.email('   '), 'Email is required!');
    });
    test('TC-02 malformed -> "Invalid email format"', () {
      expect(AuthValidators.email('not-an-email'), 'Invalid email format');
      expect(AuthValidators.email('a@b'), 'Invalid email format');
    });
    test('TC-03 well-formed -> null (trims surrounding space)', () {
      expect(AuthValidators.email('chaiudom@gmail.com'), isNull);
      expect(AuthValidators.email('  guide@gmail.com  '), isNull);
    });
  });

  group('UTC-24 AuthValidators.password', () {
    test('TC-01 null / shorter than 6 -> message', () {
      expect(AuthValidators.password(null),
          'Password must be at least 6 characters');
      expect(AuthValidators.password('123'),
          'Password must be at least 6 characters');
      expect(AuthValidators.password('12345'),
          'Password must be at least 6 characters');
    });
    test('TC-02 exactly 6 or longer -> null', () {
      expect(AuthValidators.password('123456'), isNull);
      expect(AuthValidators.password('keng123'), isNull);
    });
  });

  group('UTC-25 AuthValidators.confirmPassword', () {
    test('TC-01 differs from original -> "Passwords must match"', () {
      expect(AuthValidators.confirmPassword('secret2', 'secret1'),
          'Passwords must match');
    });
    test('TC-02 equals original -> null', () {
      expect(AuthValidators.confirmPassword('secret1', 'secret1'), isNull);
    });
  });

  group('UTC-26 AuthValidators.loginPassword', () {
    test('TC-01 null / empty -> "Enter your password"', () {
      expect(AuthValidators.loginPassword(null), 'Enter your password');
      expect(AuthValidators.loginPassword(''), 'Enter your password');
    });
    test('TC-02 non-empty (no length rule) -> null', () {
      expect(AuthValidators.loginPassword('x'), isNull);
    });
  });
}
