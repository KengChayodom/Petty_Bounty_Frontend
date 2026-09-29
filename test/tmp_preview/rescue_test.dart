import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/sightings/data/models/match_model.dart';
import 'package:petty_bounty/src/features/sightings/presentation/final_review_screen.dart';

const _sdk = '/Users/macguide/flutter 2/bin/cache/artifacts/material_fonts';
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
            imageUrl: 'https://example.invalid/1.jpg',
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
