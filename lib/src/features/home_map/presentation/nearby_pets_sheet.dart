import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_glass.dart';
import '../domain/entities/missing_pet_entity.dart';
import '../domain/providers/nearby_pets_providers.dart';

/// The nearby missing pets, listed nearest first — opened from the map's
/// summary card.
///
/// Pops the pet that was tapped rather than acting on the map itself, so the
/// map screen keeps ownership of its own camera and this stays a list.
class NearbyPetsSheet extends ConsumerWidget {
  const NearbyPetsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = [...ref.watch(nearbyPetsProvider.select((s) => s.pets))]
      // Nulls last: `distance_meters` comes from the nearby RPC, so a pet that
      // arrived by another route has none rather than a distance of zero.
      ..sort((a, b) {
        final da = a.distanceMeters, db = b.distanceMeters;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          // Solid rather than frosted: a BackdropFilter over half the screen,
          // with the sonar sweeping behind it, is a lot to re-blur every frame
          // for a surface whose only job is to be read.
          color: Colors.white,
          border: Border(top: BorderSide(color: kInk.withValues(alpha: 0.08))),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: kInk.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nearby missing pets',
                      style: TextStyle(
                        color: kInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${pets.length}',
                    style: const TextStyle(
                      color: kBrandDeep,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: kInk.withValues(alpha: 0.08)),
            Expanded(
              child: ListView.separated(
                // The sheet's own controller, so dragging the list drags the
                // sheet once the list is at its top.
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: pets.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 88,
                  endIndent: 16,
                  color: kInk.withValues(alpha: 0.07),
                ),
                itemBuilder: (context, i) => _PetRow(pet: pets[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({required this.pet});

  final MissingPetEntity pet;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(pet),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: pet.imageUrl,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                placeholder: (_, _) => const _PhotoFallback(),
                errorWidget: (_, _, _) => const _PhotoFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pet.petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    // Species as words now that the emoji is gone — it was the
                    // only thing saying whether this was a cat or a dog.
                    '${pet.species} · ${_distance(pet.distanceMeters)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: kInk.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kBrandLight, kBrand],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '฿${NumberFormat('#,##0').format(pet.bountyAmount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _distance(double? meters) {
    if (meters == null) return 'Distance unknown';
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}

/// Stands in for the photo while it loads, and when it cannot be loaded at
/// all — the same box either way, so the row never changes height.
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kInk.withValues(alpha: 0.07),
      child: Icon(Icons.pets, color: kInk.withValues(alpha: 0.35)),
    );
  }
}
