import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/sightings/domain/entities/match_model.dart';
import 'package:petty_bounty/src/features/sightings/presentation/final_review_screen.dart';

// The fonts ship with whichever Flutter SDK runs the test, so the path is
// taken from that SDK rather than from one developer's machine. `flutter test`
// sets FLUTTER_ROOT; failing that, flutter_tester lives five levels below the
// SDK root (bin/cache/artifacts/engine/<platform>/flutter_tester).
final String _sdk = () {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent.parent.parent.parent.parent.parent.path;
  return '$root/bin/cache/artifacts/material_fonts';
}();
Future<ByteData> _b(String p) async =>
    ByteData.sublistView(await File(p).readAsBytes());

void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(_b('$_sdk/MaterialIcons-Regular.otf'))).load();
    for (final f in ['Roboto', '.SF UI Text', '.SF Pro Text']) {
      await (FontLoader(f)
            ..addFont(_b('$_sdk/Roboto-Regular.ttf'))
            ..addFont(_b('$_sdk/Roboto-Bold.ttf'))).load();
    }
  });

  testWidgets('spotted then rescue', (t) async {
    t.view..physicalSize = const Size(390, 844)..devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FinalReviewScreen(
          match: MatchModel(
            id: '1', petName: 'Mochi', species: 'Cat',
            characteristics: const {}, bountyAmount: 25000,
            lastSeenLocation: 'Bangkok',
            lastSeenTime: '2026-09-28T09:00:00Z',
            // Empty, so the avatar shows its placeholder: a URL would load
            // through the image cache, which needs sqflite and so cannot run
            // under `flutter test`.
            imageUrl: '',
            similarity: 0.94, distanceMeters: 320, status: 'searching',
          ),
          imagePath: null,
          latitude: 13.7563,
          longitude: 100.5018,
          sightingId: 's1',
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 200));

    void dump(String when) {
      final avatars = t.widgetList<CircleAvatar>(find.byType(CircleAvatar))
          .map((a) => a.backgroundColor)
          .toList();
      debugPrint('RESULT $when avatar backgrounds: $avatars');
    }

    dump('SPOTTED selected:');
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 120));
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('shots/spotted.png'));

    await t.tap(find.text('RESCUE'));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 120));
    }
    dump('RESCUE  selected:');
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('shots/rescue.png'));
    t.takeException();
  });
}
