// Widget tests for the owner's "Edit Report" form (SRS-66 / MD-39 / UD-11).
//
// What these pin:
//   * the form opens pre-filled from the existing report — an edit screen that
//     starts blank would silently wipe fields the owner didn't touch;
//   * a blank name can't be saved (SRS-57 keeps the name required);
//   * Save sends exactly the editable fields to PATCH /missing-pets/{id}, with
//     the untouched characteristics keys carried through;
//   * a backend failure keeps the page open with the error shown (UD-11 [E1]).
//
// No network: the form takes a seeded entity directly and the repository is a
// fake, so neither the pet-detail resolver nor the photo eyedropper is reached.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/lost_pet_post/data/lost_pet_post_repository.dart';
import 'package:petty_bounty/src/features/lost_pet_post/presentation/edit_lost_pet_post_screen.dart';
import 'package:petty_bounty/src/features/home_map/domain/entities/missing_pet_entity.dart';

class _FakeRepo extends Fake implements LostPetPostRepository {
  String? lastPetId;
  Map<String, dynamic>? lastPatch;
  int calls = 0;
  Object? error;

  @override
  Future<void> updateLostPetPost(
    String petId,
    Map<String, dynamic> patch,
  ) async {
    calls++;
    lastPetId = petId;
    lastPatch = patch;
    if (error != null) throw error!;
  }
}

MissingPetEntity _pet({
  double bounty = 1000,
  Map<String, dynamic>? characteristics,
}) {
  return MissingPetEntity(
    id: 'pet-1',
    ownerId: 'owner-1',
    petName: 'Mochi',
    species: 'Cat',
    characteristics: characteristics ??
        {
          'color': '#333333',
          'breed': 'Scottish Fold',
          'traits': 'shy, one white paw',
        },
    bountyAmount: bounty,
    latitude: 13.7,
    longitude: 100.5,
    lastSeenTime: '2026-08-01T10:00:00Z',
    imageUrl: 'https://example.test/mochi.jpg',
    status: 'Searching',
    createdAt: '2026-08-01T10:00:00Z',
    primaryColorHex: '#333333',
  );
}

Future<_FakeRepo> _pump(
  WidgetTester tester, {
  MissingPetEntity? pet,
  Object? error,
}) async {
  // The form is a scrolling column of four cards plus the Save button; give
  // the surface enough height that every field and the button are on screen
  // without needing to drag-scroll between interactions.
  await tester.binding.setSurfaceSize(const Size(1200, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final repo = _FakeRepo()..error = error;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lostPetPostRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Scaffold(body: EditReportForm(pet: pet ?? _pet())),
      ),
    ),
  );
  return repo;
}

void main() {
  testWidgets('opens pre-filled from the existing report', (tester) async {
    await _pump(tester);

    expect(find.widgetWithText(TextFormField, 'Mochi'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'shy, one white paw'),
      findsOneWidget,
    );
    // bounty > 0 => BOUNTY mode, amount seeded
    expect(find.widgetWithText(TextFormField, '1000'), findsOneWidget);
  });

  testWidgets('a blank name cannot be saved', (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Mochi'), '');
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();

    expect(find.text('Please enter pet name'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets('Save sends only the editable fields, keeping untouched keys',
      (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mochi'),
      'Mochi II',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '1000'),
      '2500',
    );
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();

    expect(repo.calls, 1);
    expect(repo.lastPetId, 'pet-1');
    final patch = repo.lastPatch!;
    expect(patch['pet_name'], 'Mochi II');
    expect(patch['bounty_amount'], 2500.0);
    expect(patch['primary_color_hex'], '#333333');
    final chars = patch['characteristics'] as Map<String, dynamic>;
    expect(chars['breed'], 'Scottish Fold'); // untouched key survived
    expect(chars['traits'], 'shy, one white paw');
    expect(chars['color'], '#333333');

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Changes saved successfully'), findsOneWidget);
  });

  testWidgets('blank traits are sent as the "Standard" sentinel',
      (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'shy, one white paw'),
      '',
    );
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();

    final chars = repo.lastPatch!['characteristics'] as Map<String, dynamic>;
    expect(chars['traits'], 'Standard');
  });

  testWidgets('a backend failure keeps the page open with the error shown',
      (tester) async {
    final repo = await _pump(
      tester,
      error: Exception('Missing pet pet-1 not found or not owned by you'),
    );

    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repo.calls, 1);
    expect(find.textContaining('not owned by you'), findsOneWidget);
    // still on the form
    expect(find.text('SAVE CHANGES'), findsOneWidget);
  });

  testWidgets('HELP FREE mode sends bounty 0', (tester) async {
    final repo = await _pump(tester, pet: _pet(bounty: 5000));

    await tester.tap(find.text('HELP FREE'));
    await tester.pump();
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pump();

    expect(repo.lastPatch!['bounty_amount'], 0.0);
  });
}
