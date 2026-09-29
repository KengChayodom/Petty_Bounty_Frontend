import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_glass.dart';
import '../../../core/ui/full_image_view.dart';
import '../../../core/ui/skeleton/skeleton.dart';
import '../data/models/match_model.dart';
import '../data/sighting_repository.dart';
import 'report_sent_screen.dart';

/// Rescue is an outcome, not an action the way spotting is: the pet is safe.
/// The app already reads this green as "confirmed" on the verification and
/// matching screens, so it carries the same meaning here.
const Color _rescueGreen = Color(0xFF047857);

/// Final review before a discovery sighting is reported to the matched pet's
/// owner. The sighting itself was already persisted upstream (at species
/// confirmation); this screen lets the hunter pick the action type and confirm
/// it via `PATCH /sightings/{id}/action` before the "sent" acknowledgement.
class FinalReviewScreen extends ConsumerStatefulWidget {
  const FinalReviewScreen({
    super.key,
    required this.match,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    this.sightingId,
  });

  final MatchModel match;
  final String? imagePath;
  final double latitude;
  final double longitude;

  /// Id of the sighting created upstream (at species confirmation). Needed to
  /// PATCH its action_type. Null falls back to navigating without persisting.
  final String? sightingId;

  @override
  ConsumerState<FinalReviewScreen> createState() => _FinalReviewScreenState();
}

class _FinalReviewScreenState extends ConsumerState<FinalReviewScreen> {
  // 'Spotted' (just saw it) or 'Caught' (rescued it). Defaults to Spotted,
  // matching the value the sighting was created with. Sending writes the
  // chosen value to the backend via PATCH /sightings/{id}/action.
  String _actionType = 'Spotted';
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDaylight,
      appBar: AppBar(
        backgroundColor: kDaylight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'FINAL REVIEW',
          style: TextStyle(
            color: kInk,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _yourPhoto(),
          const SizedBox(height: 24),
          _sectionLabel('VERIFICATION MATCH'),
          const SizedBox(height: 10),
          _matchCard(),
          const SizedBox(height: 24),
          _sectionLabel('REPORT STATUS'),
          const SizedBox(height: 10),
          _statusToggle(),
          const SizedBox(height: 24),
          _sectionLabel('LOCATION CONFIRM'),
          const SizedBox(height: 10),
          _locationPreview(),
          const SizedBox(height: 32),
          _sendButton(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
      color: Color(0x8C120A04),
    ),
  );

  Widget _yourPhoto() {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.imagePath == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullImageView.file(path: widget.imagePath!),
                  ),
                ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 130,
              height: 130,
              child: widget.imagePath != null
                  ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: kInk.withValues(alpha: 0.06),
                      child: Icon(
                        Icons.pets,
                        size: 48,
                        color: kInk.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'YOUR PHOTO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: kInk,
          ),
        ),
      ],
    );
  }

  Widget _matchCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kInk.withValues(alpha: 0.8),
              backgroundImage: widget.match.imageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(widget.match.imageUrl)
                  : null,
              child: widget.match.imageUrl.isEmpty
                  ? const Icon(Icons.pets, size: 18, color: Colors.white54)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.match.petName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '฿ ${widget.match.bountyAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: kBrand,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusToggle() {
    return Row(
      children: [
        Expanded(
          child: _statusTile(
            value: 'Spotted',
            label: 'JUST SPOTTED',
            icon: Icons.visibility_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statusTile(
            value: 'Caught',
            label: 'RESCUE',
            icon: Icons.volunteer_activism_rounded,
            accent: _rescueGreen,
            accentText: _rescueGreen,
          ),
        ),
      ],
    );
  }

  Widget _statusTile({
    required String value,
    required String label,
    required IconData icon,

    /// The colour this tile wears while it is the chosen one. Brand orange is
    /// the default because spotting is the ordinary case.
    Color accent = kBrand,
    Color accentText = kBrandDeep,
  }) {
    final selected = _actionType == value;
    return GestureDetector(
      onTap: () => setState(() => _actionType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.10)
              : kInk.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: selected
                      ? accent
                      : kInk.withValues(alpha: 0.3),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                if (selected)
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: accent,
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: selected ? accentText : kInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationPreview() {
    final point = LatLng(widget.latitude, widget.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 120,
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
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: kBrand,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _send,
        // A shimmering label bone, not a spinner. main.dart states that
        // skeletons are the app's only pending-state affordance, and
        // BusyButtonLabel exists for exactly this button shape.
        icon: _isSending
            ? const SizedBox.shrink()
            : const Icon(Icons.send_rounded, size: 18),
        label: _isSending
            ? const BusyButtonLabel(width: 150)
            : const Text(
                'CONFIRM & SEND REPORT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _send() async {
    // Persist the Spotted/Rescue choice to the sighting created upstream. The
    // sighting row itself already exists, so this write is the only thing the
    // "send" button changes; on success we move to the sent acknowledgement.
    final id = widget.sightingId;
    if (id != null) {
      setState(() => _isSending = true);
      try {
        await ref
            .read(sightingRepositoryProvider)
            .confirmSightingAction(sightingId: id, actionType: _actionType);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: kBrandErrorDeep),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReportSentScreen(
          petName: widget.match.petName,
          petImageUrl: widget.match.imageUrl,
          bounty: widget.match.bountyAmount,
          sentAt: DateTime.now(),
        ),
      ),
    );
  }
}
