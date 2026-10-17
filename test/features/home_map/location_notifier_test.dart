// Unit tests for LocationNotifier, which asks for location permission and
// finds the first position when the notifier is built.
//
// The geolocator plugin is replaced through GeolocatorPlatform.instance with a
// fake that extends GeolocatorPlatform (so it carries the platform token).
// Each case scripts the service switch, the permission answers and the two
// position reads, then builds a notifier and waits on its ready gate.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:petty_bounty/src/features/home_map/domain/providers/location_provider.dart';

const _fallback = LatLng(13.7563, 100.5018);

Position _pos(double lat, double lon) => Position(
  latitude: lat,
  longitude: lon,
  timestamp: DateTime(2026, 1, 1),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator({
    this.serviceEnabled = true,
    this.checked = LocationPermission.whileInUse,
    this.requested = LocationPermission.whileInUse,
    this.cached,
    Future<Position> Function()? fresh,
  }) : fresh = fresh ?? (() async => _pos(13.0, 100.0));

  final bool serviceEnabled;
  final LocationPermission checked;
  final LocationPermission requested;
  final Position? cached;
  final Future<Position> Function() fresh;
  int requestCalls = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checked;

  @override
  Future<LocationPermission> requestPermission() async {
    requestCalls++;
    return requested;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => cached;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      fresh();
}

/// Latest state, read through the notifier's public listener API.
LocationState _state(LocationNotifier n) {
  late LocationState latest;
  n.addListener((s) => latest = s)();
  return latest;
}

void _expectFallback(LocationState s) {
  expect(s.isLoading, isFalse);
  expect(s.location, _fallback);
  expect(s.usedFallback, isTrue);
}

void main() {
  late GeolocatorPlatform original;
  setUp(() => original = GeolocatorPlatform.instance);
  tearDown(() => GeolocatorPlatform.instance = original);

  group('UTC-94 LocationNotifier._initLocation', () {
    test('TC-01 location service off -> default point, gate released', () async {
      final geo = _FakeGeolocator(serviceEnabled: false);
      GeolocatorPlatform.instance = geo;

      final n = LocationNotifier();
      await n.ready;

      _expectFallback(_state(n));
      expect(geo.requestCalls, 0);
    });

    test('TC-02 permission not yet given -> asks, then uses the fresh fix', () async {
      final geo = _FakeGeolocator(
        checked: LocationPermission.denied,
        requested: LocationPermission.whileInUse,
      );
      GeolocatorPlatform.instance = geo;

      final n = LocationNotifier();
      await n.ready;

      final s = _state(n);
      expect(geo.requestCalls, 1);
      expect(s.location, const LatLng(13.0, 100.0));
      expect(s.usedFallback, isFalse);
      expect(s.isLoading, isFalse);
    });

    test('TC-03 asked and refused -> default point', () async {
      final geo = _FakeGeolocator(
        checked: LocationPermission.denied,
        requested: LocationPermission.denied,
      );
      GeolocatorPlatform.instance = geo;

      final n = LocationNotifier();
      await n.ready;

      expect(geo.requestCalls, 1);
      _expectFallback(_state(n));
    });

    test('TC-04 denied forever -> default point without asking again', () async {
      final geo = _FakeGeolocator(checked: LocationPermission.deniedForever);
      GeolocatorPlatform.instance = geo;

      final n = LocationNotifier();
      await n.ready;

      expect(geo.requestCalls, 0);
      _expectFallback(_state(n));
    });

    test('TC-05 cached fix -> shown and gate released before the fresh fix, '
        'then replaced by it', () async {
      final fresh = Completer<Position>();
      GeolocatorPlatform.instance = _FakeGeolocator(
        cached: _pos(14.0, 101.0),
        fresh: () => fresh.future,
      );

      final n = LocationNotifier();
      await n.ready;

      var s = _state(n);
      expect(s.location, const LatLng(14.0, 101.0));
      expect(s.usedFallback, isFalse);
      expect(s.isLoading, isFalse);

      fresh.complete(_pos(14.5, 101.5));
      await pumpEventQueue();

      s = _state(n);
      expect(s.location, const LatLng(14.5, 101.5));
      expect(s.usedFallback, isFalse);
    });

    test('TC-06 cached fix, fresh fix fails -> keeps the cached fix', () async {
      GeolocatorPlatform.instance = _FakeGeolocator(
        cached: _pos(14.0, 101.0),
        fresh: () async => throw Exception('no fix'),
      );

      final n = LocationNotifier();
      await n.ready;
      await pumpEventQueue();

      final s = _state(n);
      expect(s.location, const LatLng(14.0, 101.0));
      expect(s.usedFallback, isFalse);
    });
  });
}
