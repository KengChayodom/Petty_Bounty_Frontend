// Widget tests for MatchingResultsScreen: what it draws from the sighting state
// and where confirming a match takes the hunter.
//
// The seam is `sightingNotifierProvider`, overridden with a notifier that holds
// a fixed state. The real repository is never built. Navigation runs through a
// test GoRouter whose home route is a plain marker.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petty_bounty/src/features/sightings/data/models/sighting_model.dart';
import 'package:petty_bounty/src/features/sightings/data/sighting_repository.dart';
import 'package:petty_bounty/src/features/sightings/domain/entities/match_model.dart';
import 'package:petty_bounty/src/features/sightings/domain/sighting_providers.dart';
import 'package:petty_bounty/src/features/sightings/presentation/final_review_screen.dart';
import 'package:petty_bounty/src/features/sightings/presentation/matching_results_screen.dart';

class _UnusedRepo implements SightingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FixedNotifier extends SightingNotifier {
  _FixedNotifier(SightingState fixed) : super(_UnusedRepo()) {
    state = fixed;
  }
}

MatchModel _match(String id, String name) => MatchModel(
  id: id,
  petName: name,
  species: 'Cat',
  characteristics: const {},
  bountyAmount: 500,
  lastSeenLocation: 'POINT(100.5 13.7)',
  lastSeenTime: '2026-09-01T10:00:00Z',
  imageUrl: 'https://img.test/$id.jpg',
  similarity: 0.8,
  matchStars: 2,
  distanceMeters: 1200,
  status: 'Searching',
);

const _sighting = SightingModel(
  id: 'sighting-7',
  hunterId: 'h1',
  imageUrl: 'https://img.test/s.jpg',
  sightedLocation: 'POINT(100.5 13.7)',
  detectedSpecies: 'Cat',
  actionType: 'Spotted',
  sightingStatus: 'Pending_Analysis',
  createdAt: '2026-09-01T10:00:00Z',
);

Future<void> _pump(
  WidgetTester tester,
  SightingState state, {
  double? latitude = 13.7,
  double? longitude = 100.5,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/results',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('HOME MAP')),
      ),
      GoRoute(
        path: '/results',
        builder: (_, _) =>
            MatchingResultsScreen(latitude: latitude, longitude: longitude),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sightingNotifierProvider.overrideWith((ref) => _FixedNotifier(state)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

/// The large photo of the pet being compared, told apart from the list
/// thumbnails by its size.
String? _comparedPhotoUrl(WidgetTester tester) => tester
    .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
    .firstWhere((image) => image.width == 162)
    .imageUrl;

void main() {
  final mochi = _match('p1', 'Mochi');
  final tofu = _match('p2', 'Tofu');

  group('UTC-99 MatchingResultsScreen._buildContent', () {
    testWidgets('TC-01 no matches and not loading shows the empty message', (
      tester,
    ) async {
      await _pump(tester, const SightingState());

      expect(find.text('No matching pets found nearby'), findsOneWidget);
      expect(find.text('CONFIRM MATCH'), findsNothing);
    });

    testWidgets('TC-02 matches are listed in the order given, first compared', (
      tester,
    ) async {
      await _pump(tester, SightingState(matches: [mochi, tofu]));

      expect(find.text('No matching pets found nearby'), findsNothing);
      final mochiTop = tester.getTopLeft(find.text('Mochi')).dy;
      final tofuTop = tester.getTopLeft(find.text('Tofu')).dy;
      expect(mochiTop, lessThan(tofuTop));
      expect(_comparedPhotoUrl(tester), mochi.imageUrl);
    });

    testWidgets('TC-03 a tapped candidate becomes the compared pet', (
      tester,
    ) async {
      await _pump(tester, SightingState(matches: [mochi, tofu]));

      await tester.tap(find.text('Tofu'));
      await tester.pump();

      expect(_comparedPhotoUrl(tester), tofu.imageUrl);
    });

    testWidgets('TC-04 no matches while still loading shows no empty message', (
      tester,
    ) async {
      await _pump(tester, const SightingState(isLoading: true));

      expect(find.text('No matching pets found nearby'), findsNothing);
      expect(find.text('CONFIRM MATCH'), findsOneWidget);
    });

    testWidgets('TC-05 the compared card shows photo, name, bounty and distance', (
      tester,
    ) async {
      await _pump(tester, SightingState(matches: [mochi]));

      expect(_comparedPhotoUrl(tester), mochi.imageUrl);
      expect(find.text('Mochi'), findsWidgets);
      expect(find.text('500'), findsWidgets);
      expect(find.text('1.2 km'), findsWidgets);
    });
  });

  group('UTC-100 MatchingResultsScreen._confirmMatch', () {
    testWidgets('TC-01 with a location opens the final review of the match', (
      tester,
    ) async {
      await _pump(
        tester,
        SightingState(sighting: _sighting, matches: [mochi, tofu]),
      );

      await tester.tap(find.text('CONFIRM MATCH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final review = tester.widget<FinalReviewScreen>(
        find.byType(FinalReviewScreen),
      );
      expect(review.match, mochi);
      expect(review.sightingId, 'sighting-7');
      expect(review.latitude, 13.7);
      expect(review.longitude, 100.5);
    });

    testWidgets('TC-02 without a location returns to the Home Map', (
      tester,
    ) async {
      await _pump(
        tester,
        SightingState(sighting: _sighting, matches: [mochi]),
        latitude: null,
        longitude: null,
      );

      await tester.tap(find.text('CONFIRM MATCH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FinalReviewScreen), findsNothing);
      expect(find.text('HOME MAP'), findsOneWidget);
      expect(
        find.text(
          'Sighting submitted. The owner will be notified if it matches.',
        ),
        findsOneWidget,
      );
    });
  });
}
