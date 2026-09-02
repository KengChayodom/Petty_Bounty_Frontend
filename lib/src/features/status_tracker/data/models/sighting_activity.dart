library;

import 'package:intl/intl.dart';
import '../../../../core/constants/pet_species.dart';

/// One entry in a missing pet's sighting timeline, as returned by the
/// backend `GET /missing-pets/{id}/sightings` endpoint (the `sightings_for_pet`
/// RPC). Only maps columns the RPC actually returns.
///
/// The RPC row shape is:
///   id, hunter_id, hunter_display_name, image_url, detected_species,
///   action_type ('Spotted' | 'Caught'), sighting_status, verification_status,
///   owner_status, sighted_location (free text), created_at, similarity_score,
///   match_source.
///
/// Note: the hunter's phone number is NOT part of this RPC (the `phone` column
/// exists on `users` but isn't joined), so [hunterPhone] stays null until the
/// backend RPC is extended to select it — the UI renders the phone row only
/// when it's present rather than inventing a placeholder.
class SightingActivity {
  final String id;
  final String hunterName;
  final String? hunterPhone;
  final String? imageUrl;
  final String detectedSpecies;

  /// 'Spotted' or 'Caught' — the hunter's declared action for this sighting.
  final String actionType;

  /// 'Pending' | 'Verified' | 'Dismissed' (owner never receives Dismissed).
  /// This is the ADMINISTRATOR's moderation ruling, not the owner's — see
  /// [ownerStatus] for the verdict this screen writes.
  final String verificationStatus;

  /// The OWNER's own verdict on this card: 'Pending' | 'Confirmed' |
  /// 'Rejected'. Since 2026-08-21 this is what scoring reads, and it is what
  /// drives the queue: cards are decided oldest-first, one at a time, and
  /// confirming a 'Caught' card ends the search and pays everybody.
  final String ownerStatus;

  /// Sighting coordinates, parsed from the `sighted_location` PostGIS point
  /// (which the backend RPC returns as WKT `POINT(lng lat)` via ST_AsText).
  /// Null when the value is missing or unparseable — the card then hides the
  /// map affordance rather than dropping a pin at 0,0.
  final double? latitude;
  final double? longitude;

  final DateTime? createdAt;

  const SightingActivity({
    required this.id,
    required this.hunterName,
    this.hunterPhone,
    this.imageUrl,
    required this.detectedSpecies,
    required this.actionType,
    required this.verificationStatus,
    this.ownerStatus = 'Pending',
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  /// True when this sighting represents a physical catch/rescue rather than a
  /// mere spotting — drives the "RESCUE" styling and the confirm affordance.
  bool get isCaught => actionType.toLowerCase() == 'caught';

  bool get hasLocation => latitude != null && longitude != null;

  /// True once the owner has ruled on this card. A decided card shows a badge
  /// and offers no buttons — the backend refuses a second verdict (409).
  bool get isDecided => ownerStatus.toLowerCase() != 'pending';

  bool get isConfirmed => ownerStatus.toLowerCase() == 'confirmed';

  bool get isRejected => ownerStatus.toLowerCase() == 'rejected';

  /// Parse `POINT(lng lat)` WKT into (lat, lng). Note the coordinate order:
  /// WKT/PostGIS write X (longitude) first, then Y (latitude).
  static ({double? lat, double? lng}) _parsePointWkt(String? wkt) {
    if (wkt == null) return (lat: null, lng: null);
    final match = RegExp(
      r'POINT\s*\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)',
      caseSensitive: false,
    ).firstMatch(wkt);
    if (match == null) return (lat: null, lng: null);
    return (
      lat: double.tryParse(match.group(2)!),
      lng: double.tryParse(match.group(1)!),
    );
  }

  /// The AI's detected species for display. Normalised to our canonical label
  /// when it is one of our known species (so 'cat' and 'Cat' render the same),
  /// but the backend's own word is kept verbatim when it reports something
  /// outside our set (e.g. 'Rabbit') — we don't flatten a real detection down
  /// to 'Other'. Only a genuinely absent value falls back to 'Unknown'.
  static String _resolveDetectedSpecies(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return 'Unknown';
    // Known species render as our canonical label; anything outside the set
    // (a legacy 'Other', or a raw detection like 'Rabbit') is kept verbatim.
    return PetSpecies.fromString(value)?.label ?? value;
  }

  String get timeFormatted {
    final dt = createdAt;
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
  }

  factory SightingActivity.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['created_at'] as String?;
    if (rawCreated != null) {
      created = DateTime.tryParse(rawCreated);
    }

    final point = _parsePointWkt(json['sighted_location'] as String?);

    return SightingActivity(
      id: json['id'] as String? ?? '',
      hunterName: (json['hunter_display_name'] as String?)?.trim().isNotEmpty ==
              true
          ? (json['hunter_display_name'] as String).trim()
          : 'Anonymous Hunter',
      hunterPhone: (json['phone'] as String?)?.trim().isNotEmpty == true
          ? (json['phone'] as String).trim()
          : null,
      imageUrl: (json['image_url'] as String?)?.isNotEmpty == true
          ? json['image_url'] as String
          : null,
      detectedSpecies: _resolveDetectedSpecies(
        json['detected_species'] as String?,
      ),
      actionType: (json['action_type'] as String?) ?? 'Spotted',
      verificationStatus: (json['verification_status'] as String?) ?? 'Pending',
      // Absent reads as Pending, matching the column's NOT NULL DEFAULT: an
      // undecided card is the state every card starts in.
      ownerStatus: (json['owner_status'] as String?) ?? 'Pending',
      latitude: point.lat,
      longitude: point.lng,
      createdAt: created,
    );
  }
}
