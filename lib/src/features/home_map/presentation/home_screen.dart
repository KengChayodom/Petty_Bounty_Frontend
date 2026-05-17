// lib/src/features/home_map/presentation/home_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../domain/providers/nearby_pets_providers.dart';
import '../domain/providers/location_provider.dart'; // โหลด Provider ตัวใหม่ที่เราสร้าง
import 'marker_helper.dart';
import 'pet_detail_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  static const double _defaultSearchRadiusKm = 5.0;
  static const double _maxPanRadiusKm = 15.0;
  static const double _fetchThresholdKm = 3.0;

  Timer? _debounceTimer;
  LatLng? _lastFetchLocation;

  @override
  void initState() {
    super.initState();
    // ตอนเปิดหน้านี้มา ถ้า Riverpod มีพิกัดอยู่แล้ว (เช่น ย้อนกลับมาจากหน้าอื่น) ให้ยิง API ได้เลย
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locState = ref.read(locationProvider);
      if (locState.location != null) {
        _lastFetchLocation = locState.location;
        _fetchNearbyPets(locState.location!);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNearbyPets(LatLng location) async {
    final notifier = ref.read(nearbyPetsProvider.notifier);
    await notifier.fetchNearbyPets(
      latitude: location.latitude,
      longitude: location.longitude,
      radiusKm: _defaultSearchRadiusKm,
    );
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMoveEnd) return;

    final currentCenter = event.camera.center;

    if (_lastFetchLocation != null) {
      final distance = Geolocator.distanceBetween(
        _lastFetchLocation!.latitude,
        _lastFetchLocation!.longitude,
        currentCenter.latitude,
        currentCenter.longitude,
      );
      if (distance < _fetchThresholdKm * 1000) return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _lastFetchLocation = currentCenter;
      });
      _fetchNearbyPets(currentCenter);
    });
  }

  LatLngBounds _calculateBounds(LatLng center, double radiusKm) {
    const double kmPerDegreeLat = 111.0;
    final double kmPerDegreeLng = 111.0 * cos(center.latitude * pi / 180);

    final double latOffset = radiusKm / kmPerDegreeLat;
    final double lngOffset = radiusKm / kmPerDegreeLng;

    return LatLngBounds(
      LatLng(center.latitude - latOffset, center.longitude - lngOffset),
      LatLng(center.latitude + latOffset, center.longitude + lngOffset),
    );
  }

  void _onMarkerTap(String petId) {
    ref.read(selectedPetIdProvider.notifier).state = petId;
    _showPetDetailBottomSheet();
  }

  void _showPetDetailBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PetDetailSheet(),
    );
  }

  List<CircleMarker> _getCircleMarkers(NearbyPetsState state) {
    final markers = <CircleMarker>[];
    if (state.currentLatitude != null && state.currentLongitude != null) {
      markers.add(
        MarkerHelper.createSearchRadiusCircle(
          LatLng(state.currentLatitude!, state.currentLongitude!),
          _defaultSearchRadiusKm * 1000,
        ),
      );
    }
    return markers;
  }

  List<Marker> _getMarkers(NearbyPetsState state) {
    final markers = <Marker>[];
    if (state.currentLatitude != null && state.currentLongitude != null) {
      markers.add(
        MarkerHelper.createUserMarker(
          LatLng(state.currentLatitude!, state.currentLongitude!),
        ),
      );
    }
    markers.addAll(MarkerHelper.createPetMarkers(state.pets, _onMarkerTap));
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // ดักฟังว่าถ้า GPS เพิ่งหาพิกัดเสร็จสดๆ ร้อนๆ (ครั้งแรกสุด) ให้สั่งโหลดข้อมูลสัตว์ทันที
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (previous?.location == null && next.location != null) {
        _lastFetchLocation = next.location;
        _fetchNearbyPets(next.location!);
      }
    });

    final locState = ref.watch(locationProvider);
    final petsState = ref.watch(nearbyPetsProvider);

    // ถ้า Riverpod ยังไม่มีพิกัด (เปิดแอปครั้งแรก) ถึงจะโชว์จอโหลด
    if (locState.isLoading || locState.location == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Finding your location...',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // คำนวณขอบเขตแผนที่
    final mapBounds = _calculateBounds(locState.location!, _maxPanRadiusKm);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: locState.location!,
              initialZoom: 15.0,
              minZoom: 8.0,
              maxZoom: 18.0,
              maxBounds: mapBounds, // ล็อกขอบเขต 15 โล
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pettybounty.app',
              ),
              CircleLayer(circles: _getCircleMarkers(petsState)),
              MarkerLayer(markers: _getMarkers(petsState)),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildSearchBar(petsState),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _buildSeamlessBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(NearbyPetsState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nearby Missing Pets',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state.isLoading
                        ? 'Fetching new area...' // ถ้ากำลังโหลด ให้โชว์ข้อความนี้
                        : (state.pets.isEmpty
                              ? 'No pets found nearby.'
                              : 'Found ${state.pets.length} pet${state.pets.length == 1 ? '' : 's'} within $_defaultSearchRadiusKm km'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // ถ้ากำลังโหลด ให้โชว์วงกลมหมุนๆ เล็กๆ แทนตัวเลข
            if (state.isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            // ถ้าไม่โหลดและมีข้อมูล ให้โชว์ตัวเลขสีส้มปกติ
            else if (state.pets.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFED7645),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.pets.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildNavIcon({
    required String iconAsset,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45, // ปรับขนาดให้พอดีขึ้น
        height: 45,
        decoration: isActive
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ), // ทำเป็นเส้นขอบสีขาว
              )
            : null,
        child: Center(
          child: Image.asset(
            iconAsset,
            width: 24,
            height: 24,
            // ลบคำสั่ง color ออกไปเลย เพื่อให้มันแสดงรูปไอคอนต้นฉบับ
          ),
        ),
      ),
    );
  }

  Widget _buildSeamlessBottomNav() {
    // สีโทนน้ำเงินเข้มให้คล้ายรูปแรก (สามารถเปลี่ยนรหัสสีได้ตามต้องการ)
    const Color navColor = Color(0xFF335BCC);

    return Stack(
      clipBehavior: Clip.none, // ยอมให้ปุ่มวงกลมทะลุขอบคอนเทนเนอร์หลักขึ้นไปได้
      alignment: Alignment.bottomCenter,
      children: [
        // 1. แถบพื้นฐาน (ทรงแคปซูล)
        Container(
          height: 65,
          decoration: BoxDecoration(
            color: navColor,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavIcon(
                iconAsset: 'assets/Map.png',
                isActive: true,
                onTap: () {},
              ),
              _buildNavIcon(
                iconAsset: 'assets/ranking.png',
                isActive: false,
                onTap: () => _showComingSoon('Ranking'),
              ),
              const SizedBox(width: 70), // เว้นที่ว่างตรงกลางให้ปุ่มกล้อง
              _buildNavIcon(
                iconAsset: 'assets/post-pet.png',
                isActive: false,
                onTap: () => _showComingSoon('Post Lost Pet'),
              ),
              _buildNavIcon(
                iconAsset: 'assets/user.png',
                isActive: false,
                onTap: () => _showComingSoon('Account'),
              ),
            ],
          ),
        ),

        Positioned(
          top: -18,
          child: GestureDetector(
            onTap: () => context.go('/camera'),
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: navColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset('assets/Camera.png', width: 50, height: 50),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
