// UTC-30  ProfileScreen._logout — Full logout  (MD-34, SRS-17, triggers SRS-20)
//
// The whole point of this method is the ORDER. `unregisterForCurrentUser`
// deletes the device row through a JWT-scoped backend call, so it has to run
// while the session is still alive; `FcmService` says so in its own doc
// ("MUST be called BEFORE auth.signOut()"). Nothing enforced that but the
// sequence of three lines, and nothing checked it. TC-02 does.
//
// The seam is `pushRegistrationProvider` / `locationTrackingProvider`, added
// 2026-09-02: both services are static singletons with private constructors, so
// they can be neither substituted nor subclassed without a narrow interface.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/core/auth/auth_service.dart';
import 'package:petty_bounty/src/core/notifications/fcm_service.dart';
import 'package:petty_bounty/src/features/home_map/data/location_publisher.dart';
import 'package:petty_bounty/src/features/profile/presentation/profile_screen.dart';

/// One shared list, so the assertions are about sequence and not just about
/// each call having happened.
class _Journal {
  final List<String> steps = [];
}

class _FakePush implements PushRegistration {
  _FakePush(this.journal);
  final _Journal journal;

  @override
  Future<void> unregisterForCurrentUser() async =>
      journal.steps.add('unregister');
}

class _FakeTracking implements LocationTracking {
  _FakeTracking(this.journal);
  final _Journal journal;

  @override
  void stop() => journal.steps.add('stop');
}

class _FakeAuth extends AuthService {
  _FakeAuth(this.journal);
  final _Journal journal;

  @override
  Future<void> signOut() async => journal.steps.add('signOut');
}

Future<void> _pumpAndLogout(WidgetTester tester, _Journal journal) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pushRegistrationProvider.overrideWithValue(_FakePush(journal)),
        locationTrackingProvider.overrideWithValue(_FakeTracking(journal)),
        authServiceProvider.overrideWithValue(_FakeAuth(journal)),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pump();
  await tester.tap(find.byIcon(Icons.logout_rounded));
  await tester.pump();
}

void main() {
  group('UTC-30 ProfileScreen._logout (MD-34)', () {
    testWidgets('TC-01 all three teardown steps run', (tester) async {
      final journal = _Journal();
      await _pumpAndLogout(tester, journal);
      expect(journal.steps, containsAll(['unregister', 'stop', 'signOut']));
    });

    testWidgets('TC-02 push is unregistered before the session ends', (
      tester,
    ) async {
      final journal = _Journal();
      await _pumpAndLogout(tester, journal);
      // The backend delete is JWT-scoped: after signOut there is no token to
      // carry, and the device row would be orphaned — still receiving pushes
      // for an account no longer signed in on this device.
      expect(journal.steps, ['unregister', 'stop', 'signOut']);
    });

    // NOT COVERED, and deliberately so: what happens when the unregister call
    // fails. `_logout` has no try/catch and `onPressed: _logout` discards the
    // Future it returns, so a failure aborts the remaining two steps and
    // escapes as an *unhandled async error* — the session stays open, location
    // keeps publishing, and the user is told nothing. A test for it cannot
    // assert cleanly (the framework reports the escaped error before
    // `takeException()` can claim it), which is itself the symptom. Fixing it
    // is a product decision — retry with the session still valid, or sign out
    // anyway and accept an orphaned device row — so it is recorded against
    // MD-34 rather than decided here.
  });
}
