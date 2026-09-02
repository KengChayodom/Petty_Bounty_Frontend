// Unit test for SightingNotifier.createTargetedSighting (MD-35, SRS-49).
//
// SRS-49 = a targeted sighting (from a pet's detail view) is submitted straight
// to that pet's owner, SKIPPING AI species analysis and similarity matching.
// This is the client-side orchestration: the notifier must call the
// repository's dedicated `createTargetedSighting` (which hits the separate
// `POST /sightings/targeted` endpoint) with the `targetPetId`, and leave
// `matches` empty.
//
// True unit test (`test` package, no widget tree): the SightingRepository is a
// hand-rolled fake injected via the notifier's constructor (`implements` +
// noSuchMethod, so the real repo — and its Supabase-touching AuthService — is
// never constructed). State is read via addListener (public API). Continues the
// UTC sequence at UTC-25.

import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/sightings/data/models/match_model.dart';
import 'package:petty_bounty/src/features/sightings/data/models/sighting_model.dart';
import 'package:petty_bounty/src/features/sightings/data/sighting_repository.dart';
import 'package:petty_bounty/src/features/sightings/domain/sighting_providers.dart';

SightingSubmitResult _cannedResult({List<MatchModel> matches = const []}) =>
    SightingSubmitResult(
      sighting: const SightingModel(
        id: 's1',
        hunterId: 'h1',
        imageUrl: 'http://img/x.jpg',
        sightedLocation: 'POINT(100.5 13.7)',
        detectedSpecies: 'Cat',
        actionType: 'Spotted',
        sightingStatus: 'Pending_Analysis',
        createdAt: '2026-01-01T00:00:00Z',
      ),
      matches: matches,
    );

/// One hand-rolled fake for the targeted path: it captures the `targetPetId`
/// and either returns [_result] or throws [_error]. Only createTargetedSighting
/// is implemented — the discovery `createSighting` stays on noSuchMethod, which
/// proves the targeted path never calls it (and keeps the real Supabase-backed
/// repo / AuthService from ever being constructed).
class _FakeRepo implements SightingRepository {
  _FakeRepo({SightingSubmitResult? result, Object? error})
      : _result = result,
        _error = error;
  final SightingSubmitResult? _result;
  final Object? _error;
  String? capturedTargetPetId;

  @override
  Future<SightingSubmitResult> createTargetedSighting({
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String detectedSpecies,
    required String targetPetId,
    String? notes,
  }) async {
    capturedTargetPetId = targetPetId;
    if (_error != null) throw _error;
    return _result!;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not used in this test');
}

/// Latest state captured via the notifier's public listener API.
SightingState _drive(SightingNotifier notifier) {
  late SightingState latest;
  final remove = notifier.addListener((s) => latest = s);
  remove();
  return latest;
}

void main() {
  group('UTC-25 SightingNotifier.createTargetedSighting (MD-35, SRS-49)', () {
    test('TC-01 calls the targeted repo method with targetPetId; matches empty',
        () async {
      final repo = _FakeRepo(result: _cannedResult());
      final notifier = SightingNotifier(repo);

      await notifier.createTargetedSighting(
        imageUrl: 'http://img/x.jpg',
        latitude: 13.7,
        longitude: 100.5,
        detectedSpecies: 'Cat',
        targetPetId: 'pet-9',
      );

      // Must route through the dedicated targeted method (not discovery
      // createSighting, which would throw via noSuchMethod) and thread the
      // pet id straight through.
      expect(repo.capturedTargetPetId, 'pet-9');
      // No AI matching in targeted mode -> no candidate matches surfaced.
      final state = _drive(notifier);
      expect(state.matches, isEmpty);
      expect(state.sighting, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('TC-02 backend error -> errorMessage set, not thrown', () async {
      final notifier = SightingNotifier(_FakeRepo(error: Exception('backend down')));

      await notifier.createTargetedSighting(
        imageUrl: 'x',
        latitude: 0,
        longitude: 0,
        detectedSpecies: 'Cat',
        targetPetId: 'pet-9',
      );

      final state = _drive(notifier);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });
  });
}
