import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/pet_species.dart';
import '../../../core/map/cached_tile_provider.dart';
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
            : "No additional description provided.");

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderImage(pet),
          const SizedBox(height: 40),
          _buildSectionTitle('DETAILS'),
          _buildDetailsRow(pet, breed),
          _buildSectionTitle('DESCRIPTION'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '" $description "',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          _buildSectionTitle('DATE LOST'),
          _buildDateLostPill(_formatDateTime(pet.lastSeenTime)),
          _buildSectionTitle('LAST SEEN LOCATION'),
          _buildSightingMap(pet),
          _buildSectionTitle('OWNER'),
          _buildOwnerCard(context, pet),
          const SizedBox(height: 30),
          _buildActionButtons(context, pet),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(MissingPetEntity pet) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Stack(
          children: [
            CachedNetworkImage(
              imageUrl: pet.imageUrl,
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
              // Skeleton, not a spinner: the bone occupies the exact 320px
              // the decoded image will take, so nothing reflows on arrival.
              placeholder: (context, url) => const Skeletonizer.zone(
                child: Bone(height: 320),
              ),
              errorWidget: (context, url, error) => Container(
                height: 320,
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 48),
              ),
            ),
            Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 45,
          left: 30,
          child: Text(
            pet.petName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: 40,
          right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Bounty',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '฿',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat('#,##0').format(pet.bountyAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          right: 35,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow(MissingPetEntity pet, String breed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDetailItem(
              'COLOR',
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _parseColor(pet.primaryColorHex),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            _buildDetailItem(
              'BREED',
              Text(
                breed,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDetailItem(
              'SPECIES',
              Text(
                PetSpecies.emojiFor(pet.species),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, Widget content) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildDateLostPill(String formattedDate) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              formattedDate,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSightingMap(MissingPetEntity pet) {
    final petLocation = LatLng(pet.latitude, pet.longitude);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 160,
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
                        color: Colors.redAccent,
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
    final ownerName = pet.ownerDisplayName?.trim();
    final displayName = ownerName?.isNotEmpty == true ? ownerName! : 'Pet Owner';
    final ownerPhone = pet.ownerPhone?.trim();
    final subtitle = ownerPhone?.isNotEmpty == true ? ownerPhone! : 'Owner';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            _buildOwnerAvatar(context, pet.ownerProfileImageUrl),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Owner avatar: the real profile photo when the backend joined one, else the
  /// blue person placeholder (same fallback while the image loads or if it
  /// errors). Decoded to the painted 50pt box to spare the raster cache.
  Widget _buildOwnerAvatar(BuildContext context, String? imageUrl) {
    Widget fallback() => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        );
    if (imageUrl == null || imageUrl.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        memCacheWidth: (50 * MediaQuery.devicePixelRatioOf(context)).round(),
        placeholder: (_, _) => fallback(),
        errorWidget: (_, _, _) => fallback(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MissingPetEntity pet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          onPressed: () {
            // TARGETED sighting: the hunter is looking at THIS pet and found
            // it. Close the sheet, then open the camera in targeted mode
            // carrying the pet's id/species/name so the verification screen
            // submits straight to the owner (no AI analyze, no matching).
            Navigator.pop(context);
            context.push('/camera', extra: {
              'targetPetId': pet.id,
              'species': pet.species,
              'petName': pet.petName,
            });
          },
          backgroundColor: Colors.blue[600],
          elevation: 0,
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
        const SizedBox(width: 20),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 15),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
