// UTC-27  RegisterScreen._submit — Sign-up submission  (MD-31, SRS-07/08/09/10)
//
// MD-31 owns the submission, not the credential store: Supabase Auth writes the
// account (SRS-08), and what this method answers for is that it passes the
// entered values on, reports success (SRS-09), routes according to whether a
// session came back (SRS-10), and turns a duplicate-email failure into its own
// message rather than GoTrue's raw wording (SRS-07).
//
// The seam is `AuthService`'s lazy GoTrue getter: a fake subclass can now be
// constructed without `Supabase.initialize()` having run, and is injected by
// overriding `authServiceProvider`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petty_bounty/src/core/auth/auth_service.dart';
import 'package:petty_bounty/src/features/auth/presentation/register_screen.dart';
import 'package:petty_bounty/src/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.response, this.throwing});

  final AuthResponse? response;
  final Object? throwing;

  int calls = 0;
  String? seenEmail;
  String? seenPassword;
  String? seenDisplayName;
  String? seenPhone;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phone,
  }) async {
    calls++;
    seenEmail = email;
    seenPassword = password;
    seenDisplayName = displayName;
    seenPhone = phone;
    if (throwing != null) throw throwing!;
    return response ?? AuthResponse();
  }
}

AuthResponse _withSession() => AuthResponse(
  session: Session(
    accessToken: 'token',
    tokenType: 'bearer',
    user: User(
      id: 'u1',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    ),
  ),
);

/// Pumps RegisterScreen behind a GoRouter, because the no-session branch calls
/// `context.pop()`. `/` is a launcher that pushes `/register` so there is
/// something to pop back to.
Future<void> _pump(WidgetTester tester, _FakeAuthService auth) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('LOGIN'))),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(auth)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  // Push rather than start here, so the no-session branch has a login page to
  // pop back to — which is the situation the real app is in.
  router.push('/register');
  await tester.pumpAndSettle();
}

/// AuthField renders its label as a sibling [Text] above the [TextFormField],
/// not inside the decoration, so the field is reached through its AuthField.
Finder _field(String label) => find.descendant(
  of: find.widgetWithText(AuthField, label),
  matching: find.byType(TextFormField),
);

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(_field('Username'), 'Kim');
  await tester.enterText(_field('Email'), '  kim@example.com  ');
  await tester.enterText(_field('Phone'), '0812345678');
  await tester.enterText(_field('Password'), 'secret123');
  await tester.enterText(_field('Confirm password'), 'secret123');
}

Future<void> _tapRegister(WidgetTester tester) async {
  // The form is taller than the 600px test viewport, so the button has to be
  // scrolled into view before it can receive the tap.
  final button = find.widgetWithText(ElevatedButton, 'Register');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('UTC-27 RegisterScreen._submit (MD-31)', () {
    testWidgets('TC-01 submits the trimmed values and confirms success', (
      tester,
    ) async {
      final auth = _FakeAuthService(response: _withSession());
      await _pump(tester, auth);
      await _fillValidForm(tester);
      await _tapRegister(tester);

      expect(auth.calls, 1);
      // SRS-08: the entered values reach the credential store, email trimmed.
      expect(auth.seenEmail, 'kim@example.com');
      expect(auth.seenPassword, 'secret123');
      expect(auth.seenDisplayName, 'Kim');
      expect(auth.seenPhone, '0812345678');
      // SRS-09: the success notice is always shown.
      expect(find.text('Registration successful'), findsOneWidget);
    });

    testWidgets('TC-02 a session sends the user on, not back to login', (
      tester,
    ) async {
      final auth = _FakeAuthService(response: _withSession());
      await _pump(tester, auth);
      await _fillValidForm(tester);
      await _tapRegister(tester);

      // SRS-10: a session exists, so the auth-stream router takes over and the
      // screen does not pop itself back to the login page.
      expect(find.text('LOGIN'), findsNothing);
    });

    testWidgets('TC-03 no session falls back to the login page', (tester) async {
      final auth = _FakeAuthService(response: AuthResponse());
      await _pump(tester, auth);
      await _fillValidForm(tester);
      await _tapRegister(tester);

      // SRS-10: email confirmation is required, so there is nothing to land on.
      expect(find.text('LOGIN'), findsOneWidget);
    });

    testWidgets('TC-04 a duplicate email gets its own message', (tester) async {
      final auth = _FakeAuthService(
        throwing: const AuthException('User already registered'),
      );
      await _pump(tester, auth);
      await _fillValidForm(tester);
      await _tapRegister(tester);

      // SRS-07: GoTrue's wording is replaced, not passed through.
      expect(find.text('Email already exists'), findsOneWidget);
      expect(find.text('User already registered'), findsNothing);
    });

    testWidgets('TC-05 any other auth failure shows its own message', (
      tester,
    ) async {
      final auth = _FakeAuthService(
        throwing: const AuthException('Password is too weak'),
      );
      await _pump(tester, auth);
      await _fillValidForm(tester);
      await _tapRegister(tester);

      expect(find.text('Password is too weak'), findsOneWidget);
      expect(find.text('Email already exists'), findsNothing);
    });

    testWidgets('TC-06 an invalid form never reaches the credential store', (
      tester,
    ) async {
      final auth = _FakeAuthService(response: _withSession());
      await _pump(tester, auth);
      // Everything valid except the confirmation, which will not match.
      await _fillValidForm(tester);
      await tester.enterText(_field('Confirm password'), 'different');
      await _tapRegister(tester);

      expect(auth.calls, 0);
      expect(find.text('Registration successful'), findsNothing);
    });
  });
}
