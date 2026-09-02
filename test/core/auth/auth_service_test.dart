// UTC-29  AuthService.signOut — End the authenticated session  (MD-33, SRS-16)
//
// MD-33 is a delegation, and what is worth pinning is the delegation itself:
// that logging out reaches GoTrue rather than only clearing something local,
// and that a failure from GoTrue is not swallowed here — MD-34, the caller,
// tears push and location down first and would otherwise leave the device
// unregistered while still holding a live session.
//
// The seam is the constructor's optional GoTrue client, which also lets the
// service be built without `Supabase.initialize()` having run.

import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/core/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingGoTrue extends GoTrueClient {
  _RecordingGoTrue({this.throwing}) : super(url: 'http://localhost:1');

  final Object? throwing;
  int signOutCalls = 0;

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOutCalls++;
    if (throwing != null) throw throwing!;
  }
}

void main() {
  group('UTC-29 AuthService.signOut (MD-33)', () {
    test('TC-01 the session is ended through GoTrue', () async {
      final gotrue = _RecordingGoTrue();
      await AuthService(auth: gotrue).signOut();
      expect(gotrue.signOutCalls, 1);
    });

    test('TC-02 a failure reaches the caller rather than being swallowed', () {
      final gotrue = _RecordingGoTrue(
        throwing: const AuthException('network unreachable'),
      );
      expect(
        () => AuthService(auth: gotrue).signOut(),
        throwsA(isA<AuthException>()),
      );
    });

    test('TC-03 building the service needs no initialised Supabase', () {
      // The seam exists so that a screen test can inject a fake without the
      // plugin being set up. Constructing must therefore not touch
      // `Supabase.instance`, which asserts when uninitialised.
      expect(() => AuthService(auth: _RecordingGoTrue()), returnsNormally);
    });
  });
}
