// Widget tests for the owner's decision queue, as ActivityCard renders it.
//
// The queue rule (2026-08-21): the owner rules on one card at a time, oldest
// first, and confirming a 'Caught' card ends the search and pays every hunter
// whose card they confirmed. The backend enforces the order — a card out of
// turn is a 409 — so what these tests pin is that the SCREEN never offers a
// button the backend would refuse, and that the two confirmations are not
// dressed as the same act: saying "that is my pet" is not saying "the search
// is over".
//
// No network: the cards are built without a photo or coordinates, so neither
// CachedNetworkImage nor the map preview is reached.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/status_tracker/data/models/sighting_activity.dart';
import 'package:petty_bounty/src/features/status_tracker/presentation/widgets/activity_card.dart';

SightingActivity _card({
  String id = 's1',
  String action = 'Spotted',
  String ownerStatus = 'Pending',
}) {
  return SightingActivity(
    id: id,
    hunterName: 'Hunter',
    detectedSpecies: 'Cat',
    actionType: action,
    verificationStatus: 'Pending',
    ownerStatus: ownerStatus,
    createdAt: DateTime(2026, 1, 1),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required SightingActivity item,
  bool showConfirmButton = false,
  bool isLocked = false,
  VoidCallback? onReject,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ActivityCard(
            item: item,
            isFirst: true,
            isLast: true,
            showConfirmButton: showConfirmButton,
            isLocked: isLocked,
            onConfirm: () {},
            onReject: onReject,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the card whose turn it is offers both verdicts', (tester) async {
    await _pump(
      tester,
      item: _card(),
      showConfirmButton: true,
      onReject: () {},
    );

    expect(find.text('THAT\'S MY PET'), findsOneWidget);
    expect(find.text('NOT MINE'), findsOneWidget);
    expect(find.textContaining('Review the earlier'), findsNothing);
  });

  testWidgets('a catch is labelled as ending the search, not as a match',
      (tester) async {
    // The two confirmations do very different things — one records a verdict,
    // the other closes the case and moves every point it will ever pay — so
    // they must not read the same on screen.
    await _pump(
      tester,
      item: _card(action: 'Caught'),
      showConfirmButton: true,
      onReject: () {},
    );

    expect(find.text('CONFIRM RESCUE'), findsOneWidget);
    expect(find.text('THAT\'S MY PET'), findsNothing);
  });

  testWidgets('a card waiting its turn is locked and says why', (tester) async {
    await _pump(tester, item: _card(), isLocked: true);

    expect(find.textContaining('Review the earlier sightings first'),
        findsOneWidget);
    expect(find.text('THAT\'S MY PET'), findsNothing);
    expect(find.text('NOT MINE'), findsNothing);
  });

  testWidgets('a decided card shows the verdict instead of buttons',
      (tester) async {
    await _pump(tester, item: _card(ownerStatus: 'Confirmed'));

    expect(find.text('YOU CONFIRMED THIS'), findsOneWidget);
    expect(find.text('THAT\'S MY PET'), findsNothing);
    expect(find.text('NOT MINE'), findsNothing);
  });

  testWidgets('a rejected card stays on the timeline with its own badge',
      (tester) async {
    // Rejections are not hidden: the owner said "not mine", which is a decision
    // worth showing back to them — and hiding it would make the queue's order
    // unreadable, since the next card is defined by what came before it.
    await _pump(tester, item: _card(ownerStatus: 'Rejected'));

    expect(find.text('YOU SAID NOT MINE'), findsOneWidget);
  });

  group('SightingActivity.fromJson', () {
    test('reads the owner verdict', () {
      final item = SightingActivity.fromJson({
        'id': 's1',
        'action_type': 'Caught',
        'owner_status': 'Confirmed',
      });

      expect(item.ownerStatus, 'Confirmed');
      expect(item.isConfirmed, isTrue);
      expect(item.isDecided, isTrue);
    });

    test('an absent verdict reads as undecided, never as a decision', () {
      // The column is NOT NULL DEFAULT 'Pending'; an old client or a partial
      // payload must not make an undecided card look ruled on, which would
      // hide the buttons the owner needs.
      final item = SightingActivity.fromJson({'id': 's1'});

      expect(item.ownerStatus, 'Pending');
      expect(item.isDecided, isFalse);
    });
  });
}
