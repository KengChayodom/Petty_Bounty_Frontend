import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/ui/skeleton/skeleton.dart';
import '../../data/models/sighting_activity.dart';

/// One node in the "RECENT ACTIVITY" timeline: a colored status dot on the
/// left rail (joined by a vertical connector) and a white info card on the
/// right showing the sighting's place, action, time, and reporting hunter.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.item,
    required this.isFirst,
    required this.isLast,
    this.showConfirmButton = false,
    this.isConfirming = false,
    this.onConfirm,
    this.onReject,
    this.onViewMap,
    this.onTapImage,
    this.onReport,
  });

  final SightingActivity item;
  final bool isFirst;
  final bool isLast;

  /// Whether to render the green "CONFIRM & END SEARCH" action inside this card
  /// (only the most-recent catch qualifies).
  final bool showConfirmButton;
  final bool isConfirming;
  final VoidCallback? onConfirm;

  /// Rejects this sighting ("not a match"), shown paired with confirm at the
  /// SPOTTED stage. Non-null only when the reject affordance should appear.
  final VoidCallback? onReject;

  /// Opens the sighting's location on a full map. Non-null only when the
  /// sighting actually carries parseable coordinates.
  final VoidCallback? onViewMap;

  /// Opens the sighting photo full-screen. Non-null only when there's a photo.
  final VoidCallback? onTapImage;

  /// Flags this sighting for moderator review (overflow menu on the photo).
  final VoidCallback? onReport;

  static const _orange = Color(0xFFF57C3A);
  static const _green = Color(0xFF4CAF7D);
  static const _red = Color(0xFFE5372A);

  @override
  Widget build(BuildContext context) {
    final Color nodeColor = item.isCaught ? _green : _orange;
    final IconData nodeIcon = item.isCaught
        ? Icons.volunteer_activism_rounded
        : Icons.visibility_rounded;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left rail: connector line behind a colored status dot.
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Top half of the connector (hidden for the first node).
                SizedBox(
                  height: 18,
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(color: nodeColor, shape: BoxShape.circle),
                  child: Icon(nodeIcon, color: Colors.white, size: 16),
                ),
                // Bottom half of the connector (hidden for the last node).
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _card(nodeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Color accent) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image (tap = full-screen) with the report (⋮) overflow
          // overlaid top-right; the map affordance sits at the card's bottom.
          Stack(
            children: [
              GestureDetector(
            onTap: onTapImage,
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: item.imageUrl != null
                  // LayoutBuilder purely to size the decode: the card's own
                  // width is a tighter ceiling than the screen's, and _card()
                  // has no BuildContext of its own.
                  ? LayoutBuilder(
                      builder: (context, constraints) => CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        // Decode to the width actually painted. Full-resolution
                        // decodes of a 2048px upload cost ~12 MB of raster
                        // cache each, so a handful of timeline cards filled
                        // Flutter's whole 100 MB ImageCache and it began
                        // evicting — then re-decoding — while scrolling.
                        memCacheWidth: (constraints.maxWidth *
                                MediaQuery.devicePixelRatioOf(context))
                            .round(),
                        placeholder: (_, _) => const Skeletonizer.zone(
                          child: Bone(width: double.infinity, height: 180),
                        ),
                        errorWidget: (_, _, _) => _imageFallback(),
                      ),
                    )
                  : _imageFallback(),
                ),
              ),
              if (onReport != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _reportButton(),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.detectedSpecies} ${item.actionType}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.actionType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                if (item.timeFormatted.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        item.timeFormatted,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                const Divider(height: 20),
                // Reporting hunter.
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.person,
                          size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.hunterName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        // Phone only when the backend actually supplies it — no
                        // fabricated placeholder number.
                        if (item.hunterPhone != null)
                          Text(
                            'Tel. ${item.hunterPhone}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Map affordance — a mini map preview with a pin and a
                // "VIEW ON MAP" overlay. Shown only with real coords.
                if (onViewMap != null) ...[
                  const SizedBox(height: 12),
                  _mapPreview(),
                ],
                if (showConfirmButton) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isConfirming ? null : onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: isConfirming
                              ? const BusyButtonLabel(width: 84, height: 12)
                              : const Text(
                                  'CONFIRM',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      if (onReject != null) ...[
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isConfirming ? null : onReject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: const Text(
                              'REJECT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small non-interactive map with a pin and a "VIEW ON MAP" overlay; tapping
  /// anywhere opens the full-screen map. Only built when coords exist.
  Widget _mapPreview() {
    final point = LatLng(item.latitude!, item.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 110,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15.0,
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
                      child: const Icon(Icons.location_pin,
                          color: Color(0xFFB5651D), size: 36),
                    ),
                  ],
                ),
              ],
            ),
            // Scrim + label; also captures the tap (map itself is inert).
            Positioned.fill(
              child: Material(
                color: Colors.black.withValues(alpha: 0.22),
                child: InkWell(
                  onTap: onViewMap,
                  child: const Center(
                    child: Text(
                      'VIEW ON MAP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.pets, size: 48, color: Colors.grey),
        ),
      );

  /// Red-flag button overlaid on the photo — opens the report menu.
  Widget _reportButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onReport,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.flag_rounded, size: 20, color: _red),
        ),
      ),
    );
  }
}
