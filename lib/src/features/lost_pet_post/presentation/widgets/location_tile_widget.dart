import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home_map/domain/providers/location_provider.dart';
import '../../domain/providers/lost_pet_post_form_provider.dart';

/// "Last seen location" tile — pulls the device's real current GPS position
/// from the app-wide [locationProvider] (same one home_screen.dart uses,
/// already handles permissions + Geolocator).
class LocationTileWidget extends ConsumerWidget {
  const LocationTileWidget({super.key});

  void _useCurrentLocation(BuildContext context, WidgetRef ref) {
    final locState = ref.read(locationProvider);

    if (locState.location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still finding your location, try again in a moment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(lostPetPostFormProvider.notifier).updateLocation(
          locState.location!.latitude,
          locState.location!.longitude,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locState.usedFallback
              ? 'GPS unavailable — using a default location instead'
              : 'Location updated to current GPS point',
        ),
        backgroundColor: locState.usedFallback ? Colors.orange : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latitude = ref.watch(
      lostPetPostFormProvider.select((state) => state.latitude),
    );
    final longitude = ref.watch(
      lostPetPostFormProvider.select((state) => state.longitude),
    );

    return GestureDetector(
      onTap: () => _useCurrentLocation(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                latitude != null && longitude != null
                    ? 'Last seen: ${latitude.toStringAsFixed(5)}, '
                        '${longitude.toStringAsFixed(5)}'
                    : 'Last seen location (Tap to use current GPS)',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.my_location, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
