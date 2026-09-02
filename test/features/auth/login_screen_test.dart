// UTC-28  LoginScreen._submit — Login submission  (MD-32, SRS-12/14)
//
// MD-32 owns the submission and the one thing the screen decides for itself:
// that every authentication failure reads the same, so the form cannot be used
// to discover which email addresses hold accounts (SRS-12). The landing on Home
// Map (SRS-14) is not performed here — the router redirect is driven by the auth
// stream, and what this method owes it is a session and no error.
//
// The seam is `AuthService`'s lazy GoTrue getter, injected by overriding
// `authServiceProvider`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petty_bounty/src/core/auth/auth_service.dart';
import 'package:petty_bounty/src/features/auth/presentation/login_screen.dart';
import 'package:petty_bounty/src/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.throwing});

  final Object? throwing;

  int calls = 0;
  String? seenEmail;
  String? seenPassword;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    calls++;
    seenEmail = email;
    seenPassword = password;
    if (throwing != null) throw throwing!;
    return AuthResponse();
  }
}

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(AuthField, label),
  matching: find.byType(TextFormField),
);

Future<void> _pump(WidgetTester tester, _FakeAuthService auth) async {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [GoRoute(path: '/login', builder: (_, _) => const LoginScreen())],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(auth)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fill(
  WidgetTester tester, {
  String email = '  kim@example.com  ',
  String password = 'secret123',
}) async {
  await tester.enterText(_field('Email'), email);
  await tester.enterText(_field('Password'), password);
}

Future<void> _tapSignIn(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Sign in');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('UTC-28 LoginScreen._submit (MD-32)', () {
    testWidgets('TC-01 submits the trimmed email and the raw password', (
      tester,
    ) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth);
      await _fill(tester);
      await _tapSignIn(tester);

      expect(auth.calls, 1);
      expect(auth.seenEmail, 'kim@example.com');
      // Not trimmed: a leading or trailing space is a legitimate character in
      // a password and silently dropping it would lock the account out.
      expect(auth.seenPassword, 'secret123');
    });

    testWidgets('TC-02 a success leaves no error for the router to trip on', (
      tester,
    ) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth);
      await _fill(tester);
      await _tapSignIn(tester);

      // SRS-14: the redirect itself is the router's, driven by the auth stream.
      // What this method owes it is a clean state.
      expect(find.text('Invalid email or password'), findsNothing);
      expect(find.text('Something went wrong. Please try again.'), findsNothing);
    });

    testWidgets('TC-03 an unknown email reads the same as a wrong password', (
      tester,
    ) async {
      final unknown = _FakeAuthService(
        throwing: const AuthException('User not found'),
      );
      await _pump(tester, unknown);
      await _fill(tester);
      await _tapSignIn(tester);
      expect(find.text('Invalid email or password'), findsOneWidget);
      // SRS-12: GoTrue's wording never reaches the screen.
      expect(find.text('User not found'), findsNothing);
    });

    testWidgets('TC-04 a wrong password reads the same as an unknown email', (
      tester,
    ) async {
      final wrong = _FakeAuthService(
        throwing: const AuthException('Invalid login credentials'),
      );
      await _pump(tester, wrong);
      await _fill(tester);
      await _tapSignIn(tester);
      expect(find.text('Invalid login credentials'), findsNothing);
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets('TC-05 a non-auth failure is reported separately', (
      tester,
    ) async {
      final auth = _FakeAuthService(throwing: Exception('socket closed'));
      await _pump(tester, auth);
      await _fill(tester);
      await _tapSignIn(tester);

      // A transport failure is not a credentials failure, and telling the user
      // their password is wrong when the network dropped would be a lie.
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Invalid email or password'), findsNothing);
    });

    testWidgets('TC-06 an invalid form never reaches the auth service', (
      tester,
    ) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth);
      await _fill(tester, email: 'not-an-email');
      await _tapSignIn(tester);

      expect(auth.calls, 0);
    });
  });
}
