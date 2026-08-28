import 'package:equatable/equatable.dart';

/// Domain entity for a missing pet
class MissingPetEntity extends Equatable {
  final String id;
  final String? ownerId;
  final String petName;
  final String species;
  final Map<String, dynamic> characteristics;
  final double bountyAmount;
  final double latitude;
  final double longitude;
  final String lastSeenTime;
  final String imageUrl;
  final String status;
  final String createdAt;
  final double? distanceMeters;
  final String? primaryColorHex;
  final String? patternId;

  /// Owner's public contact info, present only when this pet was fetched by id
  /// (GET /missing-pets/{id}); null for pets that came from a list RPC.
  final String? ownerDisplayName;
  final String? ownerPhone;
  final String? ownerProfileImageUrl;

  const MissingPetEntity({
    required this.id,
    this.ownerId,
    required this.petName,
    required this.species,
    required this.characteristics,
    required this.bountyAmount,
    required this.latitude,
    required this.longitude,
    required this.lastSeenTime,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    this.distanceMeters,
    this.primaryColorHex,
    this.patternId,
    this.ownerDisplayName,
    this.ownerPhone,
    this.ownerProfileImageUrl,
  });

  /// Get formatted characteristics as a readable string
  String get characteristicsText {
    final parts = <String>[];

    // Use new pattern_id field if available
    if (patternId != null) {
      parts.add(_capitalizeFirstLetter(patternId!));
    }

    // Fall back to legacy color from characteristics
    if (primaryColorHex == null && characteristics['color'] != null) {
      parts.add(characteristics['color'].toString());
    }
    if (characteristics['secondary_color'] != null &&
        characteristics['secondary_color'].toString().trim().isNotEmpty) {
      parts.add(characteristics['secondary_color'].toString());
    }

    if (characteristics['size'] != null) {
      parts.add(characteristics['size'].toString());
    }
    if (characteristics['markings'] != null) {
      parts.add(characteristics['markings'].toString());
    }
    if (characteristics['traits'] != null &&
        characteristics['traits'].toString().trim().isNotEmpty) {
      parts.add(characteristics['traits'].toString());
    }
    if (characteristics['description'] != null &&
        characteristics['description'].toString().trim().isNotEmpty) {
      parts.add(characteristics['description'].toString());
    }
    return parts.join(' • ');
  }

  /// Capitalize first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Get formatted bounty amount
  String get formattedBounty => '\$${bountyAmount.toStringAsFixed(0)}';

  /// Get formatted distance
  String get formattedDistance {
    if (distanceMeters == null) return 'Unknown';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.toStringAsFixed(0)}m away';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km away';
  }

  /// Get status color code
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'searching':
        return '#FF9800'; // Orange
      case 'spotted':
        return '#2196F3'; // Blue
      case 'found':
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }

  @override
  List<Object?> get props => [id, primaryColorHex, patternId];
}
