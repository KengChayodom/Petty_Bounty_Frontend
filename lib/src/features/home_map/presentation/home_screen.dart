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
import '../../../core/theme/app_glass.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/ui/skeleton/skeleton.dart';
import 'home_map_skeleton.dart';
import 'marker_helper.dart';
import 'nearby_pets_sheet.dart';
import 'user_radar_layer.dart';
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

  /// Chrome is out of the way while the user is moving the map, and comes back
  /// the moment they stop. Cheaper than a collapse button: no extra control to
  /// place, nothing to discover, and the bar is only ever gone while the user
  /// is looking at the map rather than at the bar.
  bool _chromeHidden = false;
  Timer? _showChromeTimer;

  /// How long the chrome stays away after the map stops moving.
  ///
  /// Long enough to be worth it — a bar that reappears the instant you lift
  /// your finger never really got out of the way. A tap on the map cuts the
  /// wait short, so this never stands between the user and the camera button.
  static const Duration _chromeHiddenFor = Duration(seconds: 5);

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
    // (SRS-24/26). The publisher re-reads GPS each tick and skips the denied/
    // fallback case itself, so denied users never pile up at one point.
    LocationPublisher.instance.start();

    await FcmService.instance.initForCurrentUser();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _showChromeTimer?.cancel();
    super.dispose();
  }

  /// Slides [child] out of view — [away] is the direction, as a multiple of
  /// the child's own size — while the map is being moved.
  ///
  /// Travel only, deliberately no fade. Every piece of chrome here is a
  /// [GlassSurface], and wrapping a `BackdropFilter` in an opacity layer makes
  /// Impeller log `Contents::SetInheritedOpacity should never be called when
  /// Contents::CanAcceptOpacity returns false` and fall back to an offscreen
  /// pass. The offsets are large enough to clear the screen on their own, so
  /// the fade was buying nothing.
  ///
  /// Instant rather than animated when the platform asks for reduced motion:
  /// the chrome should still get out of the way, it just should not travel.
  Widget _retractable(BuildContext context, Offset away, Widget child) {
    return AnimatedSlide(
      offset: _chromeHidden ? away : Offset.zero,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }

  /// Hides the chrome for the duration of any map gesture.
  void _updateChromeFor(MapEvent event) {
    final hiding =
        event is MapEventMoveStart ||
        event is MapEventFlingAnimationStart ||
        event is MapEventDoubleTapZoomStart ||
        event is MapEventRotateStart;
    final showing =
        event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventRotateEnd;
    // A tap is the user asking for the chrome back, not another gesture to
    // hide for — it short-circuits the wait.
    final recalled = event is MapEventTap || event is MapEventLongPress;
    if (!hiding && !showing && !recalled) return;

    _showChromeTimer?.cancel();

    if (hiding) {
      if (!_chromeHidden) setState(() => _chromeHidden = true);
      return;
    }

    if (recalled) {
      _revealChrome();
      return;
    }

    // Also covers the flash this used to have at 140 ms: a drag released with
    // velocity emits MoveEnd and then FlingAnimationStart a frame or two
    // later, and showing on MoveEnd alone brought the bar back for an instant
    // before the fling took it away again.
    _showChromeTimer = Timer(_chromeHiddenFor, _revealChrome);
  }

  void _revealChrome() {
    if (mounted && _chromeHidden) setState(() => _chromeHidden = false);
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
    _updateChromeFor(event);

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

  /// Opens the nearby list and flies to the pet the user picked.
  ///
  /// The sheet pops the pet rather than moving the map itself, so the camera
  /// stays owned here and the list stays a list.
  Future<void> _openNearbyList() async {
    final pet = await showModalBottomSheet<MissingPetEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NearbyPetsSheet(),
    );
    if (pet == null || !mounted) return;

    _animatedMapMove(LatLng(pet.latitude, pet.longitude), 16.5);
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
              // The sweep runs out to the same radius the circle above marks,
              // so a ring always lands exactly on it.
              UserRadarLayer(
                centre: locState.location!,
                radiusMeters: _defaultSearchRadiusKm * 1000,
              ),
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
                      polygonOptions: PolygonOptions(
                        borderColor: kBrand,
                        color: kBrand.withValues(alpha: 0.10),
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
                              decoration: const BoxDecoration(
                                color: kBrand,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x4D000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
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
            child: _retractable(
              context,
              const Offset(0, -3),
              Consumer(
                builder: (context, ref, _) =>
                    _buildSearchBar(ref.watch(nearbyPetsProvider)),
              ),
            ),
          ),

          Positioned(
            right: 16, // ชิดขวา
            bottom:
                MediaQuery.of(context).padding.bottom +
                110, // ยกสูงขึ้นมาไม่ให้ทับแถบเมนูด้านล่าง
            // Same frosted pane as the nav and the status card, so the three
            // pieces of chrome read as one layer floating over the map.
            child: _retractable(
              context,
              const Offset(2.5, 0),
              GlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(22)),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () {
                      final locState = ref.read(locationProvider);
                      if (locState.location != null) {
                        _mapController.move(
                          locState.location!,
                          16.0, // ยิ่งเลขเยอะยิ่งซูมใกล้
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location, size: 21),
                    color: Colors.white,
                    tooltip: 'Recentre on me',
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _retractable(
              context,
              const Offset(0, 3),
              _buildSeamlessBottomNav(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(NearbyPetsState state) {
    // Nothing to open when nothing is nearby — the card stays a plain readout.
    final canOpen = state.pets.isNotEmpty;

    return GlassSurface(
      // Raised above the default: this pane sits over map tiles, which can be
      // anything from pale fields to dense city blocks, and the count has to
      // stay readable over all of them.
      opacity: 0.68,
      child: InkWell(
        onTap: canOpen ? _openNearbyList : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Not a magnifier. Nothing here searches, and an affordance that
              // does nothing when you press it is worse than no affordance.
              Icon(Icons.pets, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nearby Missing Pets',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      state.isLoading
                          ? 'Fetching new area...'
                          : (state.pets.isEmpty
                                ? 'No pets found nearby.'
                                : 'Found ${state.pets.length} pet${state.pets.length == 1 ? '' : 's'} within $_defaultSearchRadiusKm km'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              // A bone the size of the count pill, so the card keeps its width
              // while a new area is fetched. Never a spinner.
              if (state.isLoading)
                const Skeletonizer.zone(
                  child: Bone(width: 44, height: 28, uniRadius: 14),
                )
              else if (state.pets.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kBrandLight, kBrand],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
              if (canOpen)
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    // Material icons rather than the PNG set: `Map.png` and `Camera.png` carry
    // a blue plate baked into the artwork, which is what forced the whole bar
    // to be blue. These tint, so active and inactive can actually differ.
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            size: 24,
            color: isActive ? kBrandLight : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildSeamlessBottomNav() {
    return Stack(
      clipBehavior: Clip.none, // ปุ่มกล้องทะลุขอบแถบขึ้นไปได้
      alignment: Alignment.bottomCenter,
      children: [
        GlassSurface(
          borderRadius: const BorderRadius.all(Radius.circular(35)),
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavIcon(
                  icon: Icons.map_outlined,
                  tooltip: 'Map',
                  isActive: true,
                  onTap: () {},
                ),
                _buildNavIcon(
                  icon: Icons.emoji_events_outlined,
                  tooltip: 'Leaderboard',
                  isActive: false,
                  onTap: () => context.push('/leaderboard'),
                ),
                const SizedBox(width: 70), // เว้นที่ให้ปุ่มกล้อง
                _buildNavIcon(
                  // A sheet with a plus, not a map pin: a pin put a second
                  // map-shaped glyph two slots from the Map tab's own.
                  icon: Icons.note_add_outlined,
                  tooltip: 'Post a missing pet',
                  isActive: false,
                  onTap: _openLostPetPost,
                ),
                _buildNavIcon(
                  icon: Icons.person_outline,
                  tooltip: 'Profile',
                  isActive: false,
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
          ),
        ),

        // The heaviest element on the screen by design: every pane around it
        // is glass, so the filled brand disc reads as the primary action even
        // though the active nav icon shares its colour.
        Positioned(
          top: -18,
          child: Tooltip(
            message: 'Report a sighting',
            child: GestureDetector(
              onTap: () => context.push('/camera'),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [kBrandLight, kBrand],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kBrand.withValues(alpha: 0.5),
                      blurRadius: 34,
                      spreadRadius: -8,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Pulled out of the nav so the bar stays readable — unchanged behaviour:
  /// post a pet, then fly to it and open its sheet.
  Future<void> _openLostPetPost() async {
    final result = await context.push<Map<String, dynamic>>('/lost-pet-post');
    if (result == null || !mounted) return;

    final location = result['location'] as LatLng?;
    final petId = result['petId'] as String?;
    if (location == null) return;

    await _fetchNearbyPets(location);
    _animatedMapMove(
      location,
      16.5,
      onComplete: () {
        if (petId != null && mounted) {
          ref.read(selectedPetIdProvider.notifier).state = petId;
          _showPetDetailBottomSheet();
        }
      },
    );
  }
}
