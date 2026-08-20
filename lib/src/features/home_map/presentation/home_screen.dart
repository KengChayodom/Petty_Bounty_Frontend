// lib/src/features/home_map/presentation/home_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../domain/entities/missing_pet_entity.dart';
import '../domain/providers/nearby_pets_providers.dart';
import '../domain/providers/location_provider.dart'; // โหลด Provider ตัวใหม่ที่เราสร้าง
import '../data/location_publisher.dart';
import '../../../core/map/cached_tile_provider.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/ui/skeleton/skeleton.dart';
import 'home_map_skeleton.dart';
import 'marker_helper.dart';
import 'pet_detail_sheet.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const double _defaultSearchRadiusKm = 10.0;
  static const double _maxPanRadiusKm = 15.0;
  static const double _fetchThresholdKm = 3.0;

  Timer? _debounceTimer;
  LatLng? _lastFetchLocation;

  void _animatedMapMove(
    LatLng destLocation,
    double destZoom, {
    VoidCallback? onComplete,
  }) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        if (onComplete != null) {
          onComplete();
        }
      }
    });

    controller.forward();
  }

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
      // Set up push AFTER the location permission flow settles, so the OS
      // shows the location dialog first and the notification dialog second
      // — never both at once. Home is only reachable when logged in (router
      // guard), so this also keeps push init scoped to signed-in users.
      _initPushAfterLocation();
    });
  }

  Future<void> _initPushAfterLocation() async {
    await ref.read(locationProvider.notifier).ready;
    if (!mounted) return;

    // Keep our position fresh on the backend so geo-targeted push can find us
    // (SRS-21/23). The publisher re-reads GPS each tick and skips the denied/
    // fallback case itself, so denied users never pile up at one point.
    LocationPublisher.instance.start();

    await FcmService.instance.initForCurrentUser();
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
      // Plain assignment, NOT setState: `_lastFetchLocation` is only ever read
      // back here and in initState — build() never touches it. The setState
      // this replaces rebuilt the entire map subtree (and with it every marker
      // and the whole cluster tree) for a value nothing on screen displays.
      _lastFetchLocation = currentCenter;
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

  List<CircleMarker> _getCircleMarkers(LatLng? myLocation) {
    final markers = <CircleMarker>[];
    if (myLocation != null) {
      markers.add(
        MarkerHelper.createSearchRadiusCircle(
          myLocation,
          _defaultSearchRadiusKm * 1000,
        ),
      );
    }
    return markers;
  }

  List<Marker> _getUserMarker(LatLng? myLocation) {
    if (myLocation == null) return [];
    return [MarkerHelper.createUserMarker(myLocation)];
  }

  // Memoised marker list, keyed on the identity of the pets list it was built
  // from.
  //
  // MarkerClusterLayer decides whether to rebuild with
  // `oldWidget.options.markers != widget.options.markers`, and `!=` on a Dart
  // List is IDENTITY, not contents — so handing it a fresh `.toList()` made it
  // throw away and re-derive the entire cluster tree on every single build,
  // even when the same pets were on screen. Returning the identical list when
  // nothing changed is what lets that check short-circuit.
  List<MissingPetEntity>? _markerSource;
  List<Marker>? _markerCache;

  List<Marker> _petMarkersFor(List<MissingPetEntity> pets) {
    if (identical(pets, _markerSource) && _markerCache != null) {
      return _markerCache!;
    }
    _markerSource = pets;
    return _markerCache = MarkerHelper.createPetMarkers(pets, _onMarkerTap);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ เอาโค้ดชุดนี้ไปวางแทน ref.listen อันเก่าทั้งหมดเลยครับ
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (next.location != null) {
        if (previous?.location == null) {
          // โหลดข้อมูลสัตว์หายเมื่อได้พิกัดครั้งแรกสุด
          _lastFetchLocation = next.location;
          _fetchNearbyPets(next.location!);
        } else if (previous?.location != next.location) {
          _mapController.move(next.location!, _mapController.camera.zoom);

          // The first emission can be the OS's CACHED fix (see
          // LocationNotifier stage 1), and the pets above were fetched for it.
          // If the accurate fix then lands far away — the user travelled since
          // the app last ran — that list is for the wrong area, and a
          // programmatic `move` emits no MapEventMoveEnd, so `_onMapEvent`
          // will not notice. Re-fetch on the same threshold panning uses.
          final movedMeters = Geolocator.distanceBetween(
            previous!.location!.latitude,
            previous.location!.longitude,
            next.location!.latitude,
            next.location!.longitude,
          );
          if (movedMeters > _fetchThresholdKm * 1000) {
            _lastFetchLocation = next.location;
            _fetchNearbyPets(next.location!);
          }
        }
      }
    });

    final locState = ref.watch(locationProvider);
    // Deliberately NOT `ref.watch(nearbyPetsProvider)` here. Watching the whole
    // state object at the root meant an `isLoading` flip — which only the
    // search bar renders — rebuilt the map, its layers and every marker. The
    // two things that actually depend on it now subscribe individually below.

    // ถ้า Riverpod ยังไม่มีพิกัด (เปิดแอปครั้งแรก) ถึงจะโชว์จอโหลด
    // Skeleton of the map screen's chrome — no spinner. See HomeMapSkeleton.
    if (locState.isLoading || locState.location == null) {
      return const HomeMapSkeleton();
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
                urlTemplate:
                    'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.pettybounty.app',
                // Disk-backed, so a returning user's map paints from local
                // storage instead of re-downloading every tile. See
                // MapTileCache for why tiles get their own cache store.
                tileProvider: CachedTileProvider(),
              ),
              CircleLayer(circles: _getCircleMarkers(locState.location)),
              // 1. หมุดตำแหน่งของเรา (อยู่เดี่ยวๆ)
              MarkerLayer(markers: _getUserMarker(locState.location)),

              // Scoped to `pets` alone via select(): NearbyPetsState.copyWith
              // passes the same List instance through when only isLoading
              // changes, so this subtree does not rebuild while a fetch is in
              // flight — only when the pets themselves actually change.
              Consumer(
                builder: (context, ref, _) {
                  final pets = ref.watch(
                    nearbyPetsProvider.select((s) => s.pets),
                  );
                  return MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 120, // รวบหมุดในระยะ 120 พิกเซล
                      size: const Size(
                        55,
                        55,
                      ), // ขนาดกล่องเพื่อให้มีที่วางตัวเลขมุมขวาบน
                      markers: _petMarkersFor(pets),
                      polygonOptions: const PolygonOptions(
                        borderColor: Colors.blueAccent,
                        color: Colors.black12,
                        borderStrokeWidth: 3,
                      ),
                      builder: (context, markers) {
                        return Stack(
                          clipBehavior: Clip.none, // ยอมให้ป้ายตัวเลขล้นขอบได้
                          alignment: Alignment.center,
                          children: [
                            // ✅ ส่วนฐาน: วงกลมสีส้มและไอคอนอุ้งเท้า (ไม่ใช่รูป Me แล้ว!)
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFFED7645), // สีส้มธีมแอป
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.pets, // เปลี่ยนเป็นรูปอุ้งเท้า
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            // ✅ ส่วนป้ายแจ้งเตือน (มุมขวาบน): วงกลมสีแดงพร้อมตัวเลข
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors
                                      .redAccent, // ใช้สีแดงให้ตัวเลขเด้งสะดุดตา
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${markers.length}', // จำนวนแมวที่ทับกัน
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            // The only widget that renders `isLoading`. Subscribing here
            // rather than at the root is what keeps a fetch from rebuilding
            // the map underneath it.
            child: Consumer(
              builder: (context, ref, _) =>
                  _buildSearchBar(ref.watch(nearbyPetsProvider)),
            ),
          ),

          Positioned(
            right: 16, // ชิดขวา
            bottom:
                MediaQuery.of(context).padding.bottom +
                110, // ยกสูงขึ้นมาไม่ให้ทับแถบเมนูด้านล่าง
            child: FloatingActionButton(
              mini: true, // ทำให้ปุ่มเล็กลงหน่อย จะได้ไม่เกะกะแผนที่
              backgroundColor: Colors.white,
              elevation: 4,
              heroTag: 'recenter',
              onPressed: () {
                final locState = ref.read(locationProvider);
                if (locState.location != null) {
                  _mapController.move(
                    locState.location!,
                    16.0, // ระดับการซูม (ยิ่งเลขเยอะยิ่งซูมใกล้ ปรับได้ตามชอบ)
                  );
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blueAccent),
            ),
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
            // ถ้ากำลังโหลด ให้โชว์โครงร่างป้ายตัวเลข (ไม่ใช้วงกลมหมุนๆ)
            // A bone the size of the count pill, so the card keeps its width
            // while a new area is fetched.
            if (state.isLoading)
              const Skeletonizer.zone(
                child: Bone(width: 44, height: 28, uniRadius: 14),
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
                onTap: () async {
                  final result = await context.push<Map<String, dynamic>>(
                    '/lost-pet-post',
                  );
                  if (result != null && mounted) {
                    final location = result['location'] as LatLng?;
                    final petId = result['petId'] as String?;
                    if (location != null) {
                      await _fetchNearbyPets(location);
                      _animatedMapMove(
                        location,
                        16.5,
                        onComplete: () {
                          if (petId != null && mounted) {
                            ref.read(selectedPetIdProvider.notifier).state =
                                petId;
                            _showPetDetailBottomSheet();
                          }
                        },
                      );
                    }
                  }
                },
              ),
              _buildNavIcon(
                iconAsset: 'assets/user.png',
                isActive: false,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),

        Positioned(
          top: -18,
          child: GestureDetector(
            onTap: () => context.push('/camera'),
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
