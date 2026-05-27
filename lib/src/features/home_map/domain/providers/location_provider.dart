import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationState {
  final bool isLoading;
  final LatLng? location;

  LocationState({this.isLoading = true, this.location});
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
   
    if (state.location != null) return; 

    try {
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
      state = LocationState(isLoading: false, location: const LatLng(13.7563, 100.5018));
    }
  }
}

// Provider ตัวนี้จะเป็นคนจำพิกัดให้เราตลอดการใช้งานแอป
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});