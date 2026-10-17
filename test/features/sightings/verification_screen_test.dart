// Widget tests for VerificationScreen on the discovery path: what it does with
// the AI analysis result, and what the species confirmation dialog decides.
//
// Seams: `sightingRepositoryProvider` is overridden with a fake that answers
// the analysis and records the submitted species, the photo upload arrives as a
// `PendingUpload`, and the device location comes from a fake
// `GeolocatorPlatform.instance`. A test GoRouter supplies the named route the
// screen moves to after a submission.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:petty_bounty/src/features/sightings/data/models/sighting_model.dart';
import 'package:petty_bounty/src/features/sightings/data/sighting_repository.dart';
import 'package:petty_bounty/src/features/sightings/domain/pending_upload.dart';
import 'package:petty_bounty/src/features/sightings/domain/sighting_providers.dart';
import 'package:petty_bounty/src/features/sightings/presentation/verification_screen.dart';

const _connectionError = 'Connection error. Ensure backend is running.';
const _noAnimal = 'No target animal detected, please try again.';

class _FakeRepo implements SightingRepository {
  _FakeRepo(this.analysis);

  final Map<String, dynamic> analysis;
  String? analyzedUrl;
  String? submittedSpecies;

  @override
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    analyzedUrl = imageUrl;
    return analysis;
  }

  @override
  Future<SightingSubmitResult> createSighting({
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String detectedSpecies,
    String? notes,
  }) async {
    submittedSpecies = detectedSpecies;
    return const SightingSubmitResult(
      sighting: SightingModel(
        id: 's1',
        hunterId: 'h1',
        imageUrl: 'https://img.test/up.jpg',
        sightedLocation: 'POINT(100.5 13.7)',
        detectedSpecies: 'Cat',
        actionType: 'Spotted',
        sightingStatus: 'Pending_Analysis',
        createdAt: '2026-09-01T10:00:00Z',
      ),
      matches: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: 13.7,
    longitude: 100.5,
    timestamp: DateTime(2026, 9, 1),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

Map<String, dynamic> _found(String? species) => {
  'status': 'success',
  'data': {'species': species, 'confidence': 0.9},
};

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  PendingUpload? upload,
}) async {
  final pending =
      upload ?? PendingUpload(Future.value('https://img.test/up.jpg'));
  final router = GoRouter(
    initialLocation: '/verify',
    routes: [
      GoRoute(
        path: '/verify',
        builder: (_, _) => VerificationScreen(
          imagePath: '/no/such/photo.jpg',
          pendingUpload: pending,
        ),
      ),
      GoRoute(
        path: '/results',
        name: 'matching-results',
        builder: (_, _) => const Text('MATCHING RESULTS'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sightingRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  late GeolocatorPlatform realGeolocator;
  setUp(() {
    realGeolocator = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _FakeGeolocator();
  });
  tearDown(() => GeolocatorPlatform.instance = realGeolocator);

  group('UTC-101 VerificationScreen._processAIAnalysis', () {
    testWidgets('TC-01 a detected species opens the confirmation dialog', (
      tester,
    ) async {
      final repo = _FakeRepo(_found('Cat'));
      await _pump(tester, repo);

      expect(repo.analyzedUrl, 'https://img.test/up.jpg');
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Is this a Cat ?', findRichText: true), findsOneWidget);
      expect(find.text(_noAnimal), findsNothing);
    });

    testWidgets('TC-02 a not_found answer shows the no-animal message', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo({'status': 'not_found', 'data': null}));

      expect(find.text(_noAnimal), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('TC-03 an Unknown species shows the no-animal message', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo(_found('Unknown')));

      expect(find.text(_noAnimal), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('TC-04 a failed upload shows the connection error and stays', (
      tester,
    ) async {
      final repo = _FakeRepo(_found('Cat'));
      await _pump(
        tester,
        repo,
        upload: PendingUpload(Future.error(Exception('upload failed'))),
      );

      expect(find.text(_connectionError), findsOneWidget);
      expect(find.byType(VerificationScreen), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(repo.analyzedUrl, isNull);
    });

    testWidgets('TC-05 the analysing display stays until the result arrives', (
      tester,
    ) async {
      final upload = Completer<String>();
      await _pump(
        tester,
        _FakeRepo({'status': 'not_found', 'data': null}),
        upload: PendingUpload(upload.future),
      );

      expect(find.text('AI is analyzing...'), findsOneWidget);

      upload.complete('https://img.test/up.jpg');
      await tester.pump();
      await tester.pump();

      expect(find.text('AI is analyzing...'), findsNothing);
      expect(find.text(_noAnimal), findsOneWidget);
    });
  });

  group('UTC-102 VerificationScreen._showConfirmationDialog', () {
    testWidgets('TC-01 Yes submits the detected species', (tester) async {
      final repo = _FakeRepo(_found('Cat'));
      await _pump(tester, repo);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(repo.submittedSpecies, 'Cat');
      expect(find.text('MATCHING RESULTS'), findsOneWidget);
    });

    testWidgets('TC-02 No shows the species dropdown with Confirm disabled', (
      tester,
    ) async {
      final repo = _FakeRepo(_found('Cat'));
      await _pump(tester, repo);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('AI detected: Cat'), findsOneWidget);
      final confirm = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirm.onPressed, isNull);
      expect(repo.submittedSpecies, isNull);
    });

    testWidgets('TC-03 a species chosen after No is the one submitted', (
      tester,
    ) async {
      final repo = _FakeRepo(_found('Cat'));
      await _pump(tester, repo);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dog').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(repo.submittedSpecies, 'Dog');
      expect(find.text('MATCHING RESULTS'), findsOneWidget);
    });
  });
}
