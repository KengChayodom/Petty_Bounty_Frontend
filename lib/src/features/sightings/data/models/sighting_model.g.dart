// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sighting_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SightingModelImpl _$$SightingModelImplFromJson(Map<String, dynamic> json) =>
    _$SightingModelImpl(
      id: json['id'] as String,
      hunterId: json['hunter_id'] as String,
      imageUrl: json['image_url'] as String,
      sightedLocation: json['sighted_location'] as String,
      detectedSpecies: json['detected_species'] as String,
      actionType: json['action_type'] as String,
      sightingStatus: json['sighting_status'] as String,
      createdAt: json['created_at'] as String,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      similarity: (json['similarity'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$SightingModelImplToJson(_$SightingModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hunter_id': instance.hunterId,
      'image_url': instance.imageUrl,
      'sighted_location': instance.sightedLocation,
      'detected_species': instance.detectedSpecies,
      'action_type': instance.actionType,
      'sighting_status': instance.sightingStatus,
      'created_at': instance.createdAt,
      'distance_meters': instance.distanceMeters,
      'similarity': instance.similarity,
    };

_$SightingCreateRequestImpl _$$SightingCreateRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$SightingCreateRequestImpl(
      hunterId: json['hunter_id'] as String,
      imageUrl: json['image_url'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      detectedSpecies: json['detected_species'] as String,
      bbox: (json['bbox'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$SightingCreateRequestImplToJson(
        _$SightingCreateRequestImpl instance) =>
    <String, dynamic>{
      'hunter_id': instance.hunterId,
      'image_url': instance.imageUrl,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'detected_species': instance.detectedSpecies,
      'bbox': instance.bbox,
      'notes': instance.notes,
    };
