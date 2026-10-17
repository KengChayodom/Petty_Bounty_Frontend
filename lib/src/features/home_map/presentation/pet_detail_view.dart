import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/pet_species.dart';
import '../../../core/map/cached_tile_provider.dart';
import '../../../core/theme/app_glass.dart';
import '../../../core/ui/brand_widgets.dart';
import '../../../core/ui/skeleton/skeleton.dart';
import '../domain/entities/missing_pet_entity.dart';

Color _parseColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) return Colors.brown[300]!;

  String hex = hexColor;
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  try {
    return Color(int.parse(hex, radix: 16));
  } catch (e) {
    return Colors.brown[300]!;
  }
}

/// Presentation-only pet detail UI. Takes a fully-resolved [MissingPetEntity]
/// and renders the rich layout (bounty badge, color/breed/species, date-lost
/// pill, owner card, action buttons). Shared by BOTH entry points:
///   * the map bottom sheet (PetDetailSheet) — passes the sheet's
///     [scrollController] so drag-to-scroll links to the content;
///   * the push deep-link page (MissingPetDetailScreen) — leaves it null.
class PetDetailView extends StatelessWidget {
  const PetDetailView({super.key, required this.pet, this.scrollController});

  final MissingPetEntity pet;
  final ScrollController? scrollController;

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return 'Unknown Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String breed = pet.characteristics['breed'] ?? 'Common';
    final String traitsVal =
        (pet.characteristics['traits'] ?? pet.characteristics['description'] ?? '')
            .toString()
            .trim();
    final String description = traitsVal.isNotEmpty
        ? traitsVal
        : (pet.characteristicsText.isNotEmpty
            ? pet.characteristicsText
            : 'The owner added no description.');

    const headerHeight = 340.0;
    const overlap = 28.0;
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderImage(pet, breed, headerHeight),
          Transform.translate(
            offset: const Offset(0, -overlap),
            child: Container(
              decoration: const BoxDecoration(
                color: kDaylight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _fact('Last seen', Text(
                          _formatDateTime(pet.lastSeenTime),
                          style: _factValue,
                        )),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _fact('Colour', Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _parseColor(pet.primaryColorHex),
                                shape: BoxShape.circle,
                                border: Border.all(color: kInk.withValues(alpha: 0.15)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(breed,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _factValue),
                            ),
                          ],
                        )),
                      ),
                    ],
                  )),
                  const SizedBox(height: 22),
                  const SheetHeading('What they look like'),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 15, height: 1.45, color: kInk.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 22),
                  const SheetHeading('Last seen here'),
                  const SizedBox(height: 10),
                  _buildSightingMap(pet),
                  const SizedBox(height: 20),
                  _buildOwnerCard(context, pet),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, pet),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _factValue =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kInk);

  Widget _fact(String label, Widget value) {
    return SheetTile(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: kInk.withValues(alpha: 0.6))),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  Widget _buildHeaderImage(MissingPetEntity pet, String breed, double height) {
    final species = pet.species.trim();
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: pet.imageUrl,
            fit: BoxFit.cover,
            // Skeleton, not a spinner: the bone occupies the exact box the
            // decoded image will take, so nothing reflows on arrival.
            placeholder: (context, url) => Skeletonizer.zone(
              child: Bone(height: height),
            ),
            errorWidget: (context, url, error) => const HeroPhoto(imageUrl: null),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.3, 1],
                colors: [Color(0x59120A04), Color(0x00120A04), Color(0xBF120A04)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.petName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: displayStyle(size: 44, color: kDaylight),
                      ),
                      if (species.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${PetSpecies.emojiFor(pet.species)} $species, $breed',
                          style: TextStyle(
                              fontSize: 15, color: kDaylight.withValues(alpha: 0.88)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // The reward is what a hunter reads first.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Reward',
                        style: TextStyle(
                            fontSize: 13, color: kDaylight.withValues(alpha: 0.8))),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat('#,##0').format(pet.bountyAmount),
                      style: displayStyle(size: 36, color: kBrandLight),
                    ),
                    Text('THB',
                        style: TextStyle(
                            fontSize: 12, color: kDaylight.withValues(alpha: 0.8))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSightingMap(MissingPetEntity pet) {
    final petLocation = LatLng(pet.latitude, pet.longitude);
    return Padding(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 150,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: petLocation,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pettybounty.app',
                tileProvider: CachedTileProvider(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: petLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kBrandDeep,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context, MissingPetEntity pet) {
    // Real owner data comes from the by-id detail endpoint. When absent (pet
    // opened from an in-memory list) fall back to a generic label and 'Owner'
    // rather than inventing a name or a "Verified" claim the backend never made.
    final ownerName = pet.ownerUsername?.trim();
    final username = ownerName?.isNotEmpty == true ? ownerName! : 'Pet Owner';
    final ownerPhone = pet.ownerPhone?.trim();
    final subtitle = ownerPhone?.isNotEmpty == true ? 'Tel. ${ownerPhone!}' : 'Owner';

    return Row(
      children: [
        _buildOwnerAvatar(context, pet.ownerProfileImageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Posted by $username',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15, color: kInk),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: kInk.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Owner avatar: the real profile photo when the backend joined one, else the
  /// blue person placeholder (same fallback while the image loads or if it
  /// errors). Decoded to the painted 50pt box to spare the raster cache.
  Widget _buildOwnerAvatar(BuildContext context, String? imageUrl) {
    Widget fallback() => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFCDB6A2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.person, color: kDaylight),
        );
    if (imageUrl == null || imageUrl.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        memCacheWidth: (44 * MediaQuery.devicePixelRatioOf(context)).round(),
        placeholder: (_, _) => fallback(),
        errorWidget: (_, _, _) => fallback(),
      ),
    );
  }

  /// TARGETED sighting: the hunter is looking at THIS pet and found it.
  /// Close the sheet, then open the camera in targeted mode carrying the
  /// pet's id/species/name so the verification screen submits straight to the
  /// owner (no AI analyze, no matching).
  void _reportSighting(BuildContext context, MissingPetEntity pet) {
    Navigator.pop(context);
    context.push('/camera', extra: {
      'targetPetId': pet.id,
      'species': pet.species,
      'petName': pet.petName,
    });
  }

  Widget _buildActionButtons(BuildContext context, MissingPetEntity pet) {
    final species = pet.species.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandButton(
          label: species.isEmpty ? 'I saw this pet' : 'I saw this $species',
          icon: Icons.photo_camera_rounded,
          onPressed: () => _reportSighting(context, pet),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: kInk.withValues(alpha: 0.7),
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
