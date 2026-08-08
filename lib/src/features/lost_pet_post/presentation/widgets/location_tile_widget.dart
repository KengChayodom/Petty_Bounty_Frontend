import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';
import 'location_picker_screen.dart';

/// "Last seen location" tile — opens a full-screen map picker seeded at the
/// device's current position, so the owner can confirm it as-is or drag the
/// pin to wherever the pet was actually last seen (not just where they're
/// standing right now). Once a location is picked, shows a small static map
/// thumbnail instead of raw coordinates so it actually reads as a place.
class LocationTileWidget extends ConsumerWidget {
  const LocationTileWidget({super.key});

  Future<void> _openLocationPicker(BuildContext context, WidgetRef ref) async {
    final formState = ref.read(lostPetPostFormProvider);
    final initial = formState.latitude != null && formState.longitude != null
        ? LatLng(formState.latitude!, formState.longitude!)
        : null;

    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: initial),
      ),
    );

    if (result != null && context.mounted) {
      ref
          .read(lostPetPostFormProvider.notifier)
          .updateLocation(result.latitude, result.longitude);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latitude = ref.watch(
      lostPetPostFormProvider.select((state) => state.latitude),
    );
    final longitude = ref.watch(
      lostPetPostFormProvider.select((state) => state.longitude),
    );
    final hasLocation = latitude != null && longitude != null;

    return GestureDetector(
      onTap: () => _openLocationPicker(context, ref),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: hasLocation
            ? _LocationPreview(latitude: latitude, longitude: longitude)
            : const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Last seen location (Tap to select on map)',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.map_outlined, color: Colors.grey, size: 18),
                  ],
                ),
              ),
      ),
    );
  }
}

/// A small, non-interactive map snippet showing where the pin was dropped.
/// Interaction is ignored here — the tap is handled by the outer
/// [GestureDetector] in [LocationTileWidget].
class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return SizedBox(
      height: 110,
      child: IgnorePointer(
        child: FlutterMap(
          // `initialCenter` is only honoured the first time this element is
          // built — without a key tied to the coordinates, Flutter reuses
          // the same FlutterMap element on a location change and the camera
          // never re-centers (even though the marker/state did update).
          key: ValueKey('$latitude,$longitude'),
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.pettybounty.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 36,
                  height: 36,
                  child: const Icon(
                    Icons.location_pin,
                    color: Color(0xFF0022FF),
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
