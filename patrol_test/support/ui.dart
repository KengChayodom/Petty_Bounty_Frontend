import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:petty_bounty/main.dart' as app;
import 'config.dart';
import 'profile_journal.dart';
import 'package:petty_bounty/src/core/app_config.dart';
export 'config.dart';
export 'package:flutter/material.dart';
export 'package:flutter_test/flutter_test.dart';
part 'pages.dart';
part 'fixtures.dart';

typedef UiBody = Future<void> Function(Ui ui);

void uiTest(
  String suite,
  String title,
  UiBody body, {
  List<String> needs = const [],
  String? account = 'OWNER',
  Duration timeout = const Duration(minutes: 5),
}) {
  final fixture = UiFixture(account: account, needs: needs);
  final missing = fixture.missing;
  const developing = bool.fromEnvironment('PATROL_HOT_RESTART');
  patrolTest(
    '$suite $title${missing.isEmpty ? '' : ' [NOT RUN: missing ${missing.join(', ')}]'}',
    ($) async {
      await fixture.run($, body);
    },
    skip: missing.isNotEmpty,
    tags: [suite],
    // Patrol develop holds the last completed test open for hot restart.
    // UI waits stay bounded; MCP controls the overall develop session lifetime.
    timeout: developing ? Timeout.none : Timeout(timeout),
    config: const PatrolTesterConfig(printLogs: false),
  );
}

/// Only gestures, typed values and rendered controls. No provider overrides,
/// repository calls, fake responses, direct auth or deep-link navigation.
class Ui {
  Ui(this.$);
  final PatrolIntegrationTester $;
  ProfileJournal? profileJournal;
  late final auth = AuthPage(this);
  late final profilePage = ProfilePage(this);
  late final map = HomePage(this);
  late final sighting = SightingPage(this);
  late final owner = OwnerTrackerPage(this);
  late final rewards = RewardsPage(this);
  late final posting = PostingPage(this);
  WidgetTester get tester => $.tester;
  String cfg(String name) => UiConfig.get(name);
  Finder text(String value) => find.text(value, findRichText: true);
  Finder key(String value) => find.byKey(ValueKey(value));

  Future<void> until(
    bool Function() condition,
    String description, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final clock = Stopwatch()..start();
    while (!condition() && clock.elapsed < timeout) {
      await tester.pump(const Duration(milliseconds: 150));
      // Allow real HTTP/native work to progress under the live Patrol binding.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(condition(), isTrue, reason: description);
  }

  Future<void> see(Finder finder) async {
    await until(
      () => finder.evaluate().isNotEmpty,
      'Expected the requested control to exist',
    );
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 100));
    await until(
      () => finder.hitTestable().evaluate().isNotEmpty,
      'Expected the requested control to be visible',
    );
  }

  Future<void> seeText(String value) => see(text(value));
  Future<void> gone(Finder finder) => until(
    () => finder.evaluate().isEmpty,
    'Expected the requested control to disappear',
  );
  Future<void> tap(Finder finder) async {
    await see(finder);
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(finder.first);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> tapText(String value) => tap(text(value));
  Future<void> enter(Finder finder, String value) async {
    await see(finder);
    await tester.ensureVisible(finder.first);
    // Patrol handles live keyboard registration and repeated edits on iOS.
    // Disable value logging for every field, including passwords.
    await $.enterText(
      finder.first,
      value,
      enablePatrolLog: false,
      settlePolicy: SettlePolicy.noSettle,
    );
    final editable = find.descendant(
      of: finder.first,
      matching: find.byType(EditableText),
      matchRoot: true,
    );
    expect(
      tester.widget<EditableText>(editable).controller.text == value,
      isTrue,
      reason: 'The input field must contain the requested value',
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> scrollTo(Finder finder) async {
    for (var i = 0; i < 24; i++) {
      if (finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(finder.first);
        await tester.pump(const Duration(milliseconds: 200));
        return;
      }
      final scroll = find.byType(Scrollable).hitTestable();
      expect(scroll, findsWidgets, reason: 'Expected a scrollable screen');
      await tester.drag(scroll.last, const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 250));
    }
    fail('Requested fixture/control was not found while scrolling');
  }

  Future<void> permissions() async {
    for (var i = 0; i < 3; i++) {
      if (!await $.platform.mobile.isPermissionDialogVisible(
        timeout: const Duration(seconds: 2),
      )) {
        break;
      }
      await $.platform.mobile.grantPermissionWhenInUse();
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> start() async {
    await app.initializeAppServices();
    await $.pumpWidget(const ProviderScope(child: app.PettyBountyApp()));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> back() async {
    if (Platform.isIOS) {
      await $.platform.ios.swipeBack();
    } else {
      await $.platform.android.pressBack();
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  void disposable(String name) {
    expect(
      name.startsWith('AUTOUI-'),
      isTrue,
      reason: 'Only a named AUTOUI- fixture may be changed',
    );
  }
}
