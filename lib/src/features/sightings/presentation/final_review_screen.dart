import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/match_model.dart';
import 'report_sent_screen.dart';

/// Final review before a discovery sighting is reported to the matched pet's
/// owner. The sighting itself was already persisted upstream (at species
/// confirmation); this screen lets the hunter pick the action type and confirm
/// before the "sent" acknowledgement.
class FinalReviewScreen extends StatefulWidget {
  const FinalReviewScreen({
    super.key,
    required this.match,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
  });

  final MatchModel match;
  final String? imagePath;
  final double latitude;
  final double longitude;

  @override
  State<FinalReviewScreen> createState() => _FinalReviewScreenState();
}

class _FinalReviewScreenState extends State<FinalReviewScreen> {
  static const _orange = Color(0xFFEE6D33);

  // 'Spotted' (just saw it) or 'Caught' (rescued it). Defaults to Spotted,
  // matching the value the sighting was created with. NOTE: choosing Rescue
  // is not yet persisted — it needs a backend PATCH for action_type.
  String _actionType = 'Spotted';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'FINAL REVIEW',
          style: TextStyle(
            color: Colors.black87,
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
          color: Color(0xFF9E9E9E),
        ),
      );

  Widget _yourPhoto() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 130,
            height: 130,
            child: widget.imagePath != null
                ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.pets, size: 48, color: Colors.grey),
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
            color: Colors.black87,
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
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[800],
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
                color: _orange,
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
          ),
        ),
      ],
    );
  }

  Widget _statusTile({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _actionType == value;
    return GestureDetector(
      onTap: () => setState(() => _actionType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDEEE4) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _orange : Colors.transparent,
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
                  backgroundColor: selected ? _orange : Colors.grey[400],
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                if (selected)
                  const CircleAvatar(
                    radius: 8,
                    backgroundColor: _orange,
                    child: Icon(Icons.check, size: 11, color: Colors.white),
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
                color: selected ? _orange : Colors.grey[600],
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
                      child: const Icon(Icons.location_pin,
                          color: _orange, size: 40),
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
        onPressed: _send,
        icon: const Icon(Icons.send_rounded, size: 18),
        label: const Text(
          'CONFIRM & SEND REPORT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
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

  void _send() {
    // The sighting is already persisted; this just acknowledges and shows the
    // sent confirmation. (Persisting a Rescue action_type is a later backend
    // step.)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReportSentScreen(
          match: widget.match,
          sentAt: DateTime.now(),
        ),
      ),
    );
  }
}
