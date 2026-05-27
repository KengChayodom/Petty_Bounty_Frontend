// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MissionModelImpl _$$MissionModelImplFromJson(Map<String, dynamic> json) =>
    _$MissionModelImpl(
      id: json['id'] as String,
      hunterId: json['hunter_id'] as String,
      imageUrl: json['image_url'] as String,
      sightedLocation: json['sighted_location'] as String,
      detectedSpecies: json['detected_species'] as String,
      sightingStatus: json['sighting_status'] as String,
      createdAt: json['created_at'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$MissionModelImplToJson(_$MissionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hunter_id': instance.hunterId,
      'image_url': instance.imageUrl,
      'sighted_location': instance.sightedLocation,
      'detected_species': instance.detectedSpecies,
      'sighting_status': instance.sightingStatus,
      'created_at': instance.createdAt,
      'notes': instance.notes,
    };

_$MissionAcceptResponseImpl _$$MissionAcceptResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$MissionAcceptResponseImpl(
      status: json['status'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$MissionAcceptResponseImplToJson(
        _$MissionAcceptResponseImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };
