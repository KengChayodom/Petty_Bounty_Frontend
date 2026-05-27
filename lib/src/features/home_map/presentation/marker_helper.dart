import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../domain/entities/missing_pet_entity.dart';

/// Helper class for creating map markers
class MarkerHelper {
  /// Create a marker for the user's current location
  static Marker createUserMarker(LatLng position) {
    return Marker(
      point: position,
      width: 60,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blueAccent, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/me.png', // 💡 ดึงรูป me.png มาใช้ตรงนี้
            fit: BoxFit.cover,
            // ใส่ errorBuilder เผื่อหารูปไม่เจอ จะได้ไม่พัง
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.blue[100],
                child: const Icon(Icons.person, color: Colors.blue),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Create markers for missing pets
  static List<Marker> createPetMarkers(
    List<MissingPetEntity> pets,
    Function(String) onMarkerTap,
  ) {
    return pets.map((pet) {
      final latLng = LatLng(pet.latitude, pet.longitude);

      return Marker(
        point: latLng,
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => onMarkerTap(pet.id),
          child: _buildPetMarker(pet),
        ),
      );
    }).toList();
  }

  /// Build a custom widget marker for a pet (เหลือแค่รูปวงกลม)
  static Widget _buildPetMarker(MissingPetEntity pet) {
    return Container(
      width: 56, // ปรับให้ใหญ่ขึ้นนิดนึงเพราะไม่มีหมุดแล้ว
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _getStatusColor(pet.status), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3), // เพิ่มเงาให้รูปลอยขึ้นมาจากแผนที่
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: pet.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.pets, size: 24),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error, size: 24),
          ),
        ),
      ),
    );
  }

  /// Parse location string (PostGIS POINT format) to LatLng
  static LatLng? _parseLocation(String locationString) {
    try {
      // PostGIS ST_AsText format: "POINT(lng lat)" or with SRID
      final coords = locationString
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .replaceAll('SRID=4322;POINT(', '')
          .split(' ');

      if (coords.length >= 2) {
        final lng = double.parse(coords[0]);
        final lat = double.parse(coords[1]);
        return LatLng(lat, lng);
      }
    } catch (e) {
      // Handle parsing errors
    }
    return null;
  }

  /// Get color based on pet status
  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'searching':
        return Colors.orange;
      case 'spotted':
        return Colors.blue;
      case 'found':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Create a circle for the search radius
  static CircleMarker createSearchRadiusCircle(
    LatLng center,
    double radiusMeters,
  ) {
    return CircleMarker(
      point: center,
      radius: radiusMeters,
      useRadiusInMeter: true,
      color: Colors.blue.withValues(alpha: 0.15),
      borderStrokeWidth: 2,
      borderColor: Colors.blue.withValues(alpha: 0.3),
    );
  }
}
