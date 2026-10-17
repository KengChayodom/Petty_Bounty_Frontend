// Widget test for the camera button on HomeScreen.
//
// HomeScreen is pumped on a test GoRouter whose '/camera' route only shows a
// marker text. Its providers are replaced through ProviderScope: the location
// notifier holds a fixed position and a ready gate that never opens (so the
// push setup that waits on it never reaches Firebase), the nearby-pets use case
// returns no pets, and location tracking is a no-op. The geolocator plugin is
// replaced so the notifier's own start-up never reaches a platform channel.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:petty_bounty/src/features/home_map/domain/entities/missing_pet_entity.dart';
import 'package:petty_bounty/src/features/home_map/domain/location_tracking.dart';
import 'package:petty_bounty/src/features/home_map/domain/providers/location_provider.dart';
import 'package:petty_bounty/src/features/home_map/domain/providers/location_tracking_provider.dart';
import 'package:petty_bounty/src/features/home_map/domain/providers/nearby_pets_providers.dart';
import 'package:petty_bounty/src/features/home_map/domain/usecases/get_nearby_pets_usecase.dart';
import 'package:petty_bounty/src/features/home_map/presentation/home_screen.dart';

/// The location service reports itself off, so the notifier's own start-up
/// settles on its default point without touching a platform channel.
class _OffGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
}

class _FixedLocation extends LocationNotifier {
  _FixedLocation() {
    state = LocationState(
      isLoading: false,
      location: const LatLng(13.7563, 100.5018),
    );
  }

  @override
  Future<void> get ready => Completer<void>().future;
}

class _NoPets implements GetNearbyPetsUseCase {
  @override
  Future<List<MissingPetEntity>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not used in this test');
}

class _NoTracking implements LocationTracking {
  @override
  void start() {}

  @override
  void stop() {}
}

void main() {
  late GeolocatorPlatform original;
  setUp(() {
    original = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _OffGeolocator();
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  group('UTC-103 HomeScreen._openCamera', () {
    testWidgets('TC-01 camera button -> camera screen opened with no target pet', (tester) async {
      Object? cameraExtra = 'not opened';
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationProvider.overrideWith((ref) => _FixedLocation()),
            getNearbyPetsUseCaseProvider.overrideWithValue(_NoPets()),
            locationTrackingProvider.overrideWithValue(_NoTracking()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Report a sighting'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('camera screen'), findsOneWidget);
      // A discovery sighting: the camera is opened with no target pet.
      expect(cameraExtra, isNull);
    });
  });
}
