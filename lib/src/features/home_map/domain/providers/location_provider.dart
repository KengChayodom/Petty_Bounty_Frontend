import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      state = LocationState(isLoading: false, location: LatLng(position.latitude, position.longitude));
    } catch (e) {
      // ถ้าหา GPS ไม่ได้ ให้โผล่ที่ตำแหน่ง Default
      state = LocationState(
        isLoading: false,
        location: const LatLng(13.7563, 100.5018),
        usedFallback: true,
      );
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