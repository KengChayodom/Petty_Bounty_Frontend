import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/current_fix.dart';

class LocationState {
  final bool isLoading;
  final LatLng? location;
  // True when `location` is the hard-coded default (GPS off/denied/failed),
  // NOT a real device fix. Callers that publish the hunter's position to the
  // backend must skip fallbacks so denied users don't all cluster at one point.
  final bool usedFallback;

  LocationState({
    this.isLoading = true,
    this.location,
    this.usedFallback = false,
  });
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    _initLocation();
  }

  // Completes when the location permission/init flow has finished — whether
  // it was granted, denied, or fell back to the default point. Other startup
  // work (notably the FCM notification-permission prompt) awaits this so the
  // OS shows the location dialog FIRST and the notification dialog SECOND,
  // never two native permission dialogs at once (which the OS would drop).
  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  /// How long to wait for a fresh fix before giving up on it.
  ///
  /// geolocator configures NO time limit by default, and "the GPS never got a
  /// lock" is not an exception — it is an `await` that simply never completes.
  /// Without this the screen sits on "Finding your location..." forever, the
  /// catch below never runs, and `_ready` never completes (which also stalls
  /// FCM setup and LocationPublisher, both of which await it).
  static const Duration _fixTimeout = Duration(seconds: 10);

  Future<void> _initLocation() async {
    try {
      if (state.location != null) return;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Permission denied');
      }

      // Stage 1 — the position the OS already has. This is the plugin's own
      // documented pattern ("call getLastKnownPosition to receive a cached
      // position and update it with the result of getCurrentPosition"), and it
      // is what turns a cold start from a multi-second wait into an instant
      // map. Note this is a REAL fix of the user's, just an older one, so
      // `usedFallback` stays false — LocationPublisher may publish it.
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null) {
        state = LocationState(
          isLoading: false,
          location: LatLng(cached.latitude, cached.longitude),
        );
        // Release the gate now rather than after stage 2: push registration and
        // the location publisher have no reason to wait on extra precision, and
        // the location permission dialog (the thing the gate actually orders)
        // has already been answered above.
        if (!_ready.isCompleted) _ready.complete();
      }

      // Stage 2 — refine in the background. HomeScreen's ref.listen re-centres
      // the map on this, and re-fetches nearby pets if it lands far from the
      // cached point.
      final position = await getCurrentFix(timeLimit: _fixTimeout);
      state = LocationState(
        isLoading: false,
        location: LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      // Only fall back when we have NOTHING. Overwriting unconditionally would
      // throw away a good stage-1 position the moment stage 2 timed out, and
      // teleport a real user to the middle of Bangkok.
      if (state.location == null) {
        // ถ้าหา GPS ไม่ได้ ให้โผล่ที่ตำแหน่ง Default
        state = LocationState(
          isLoading: false,
          location: const LatLng(13.7563, 100.5018),
          usedFallback: true,
        );
      }
    } finally {
      // Always release the gate, so a denial/fallback never blocks push setup.
      if (!_ready.isCompleted) _ready.complete();
    }
  }
}

// Provider ตัวนี้จะเป็นคนจำพิกัดให้เราตลอดการใช้งานแอป
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});