// Widget test for PetDetailView._reportSighting: the targeted sighting a
// hunter starts from one missing pet's details.
//
// The details are shown on a test GoRouter route over a home route, and the
// '/camera' route only records what it was opened with, so no real camera,
// network or provider is involved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petty_bounty/src/features/home_map/domain/entities/missing_pet_entity.dart';
import 'package:petty_bounty/src/features/home_map/presentation/pet_detail_view.dart';

const _pet = MissingPetEntity(
  id: 'pet-9',
  petName: 'Mochi',
  species: 'Cat',
  characteristics: {},
  bountyAmount: 500,
  latitude: 13.7,
  longitude: 100.5,
  lastSeenTime: '2026-09-01T10:00:00Z',
  imageUrl: '',
  status: 'Searching',
  createdAt: '2026-09-01T10:00:00Z',
);

void main() {
  group('UTC-104 PetDetailView._reportSighting', () {
    testWidgets(
      'TC-01 the report button opens the camera targeted at this pet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.5;
        addTearDown(tester.view.reset);

        Object? cameraExtra = 'not opened';
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('home')),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (_, _) =>
                      const Scaffold(body: PetDetailView(pet: _pet)),
                ),
              ],
            ),
            GoRoute(
              path: '/camera',
              builder: (_, state) {
                cameraExtra = state.extra;
                return const Scaffold(body: Text('camera screen'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.push('/detail');
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        await tester.ensureVisible(find.text('I saw this cat'));
        await tester.tap(find.text('I saw this cat'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('camera screen'), findsOneWidget);
        expect(cameraExtra, {
          'targetPetId': 'pet-9',
          'species': 'Cat',
          'petName': 'Mochi',
        });

        // The details were closed before the camera opened, so leaving the
        // camera returns to where the hunter came from, not to the details.
        router.pop();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('home'), findsOneWidget);
        expect(find.byType(PetDetailView), findsNothing);
      },
    );
  });
}
