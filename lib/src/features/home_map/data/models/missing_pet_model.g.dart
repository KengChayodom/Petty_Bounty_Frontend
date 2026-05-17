// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_pet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MissingPetModelImpl _$$MissingPetModelImplFromJson(
        Map<String, dynamic> json) =>
    _$MissingPetModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      petName: json['pet_name'] as String,
      species: json['species'] as String,
      characteristics: json['characteristics'] as Map<String, dynamic>,
      bountyAmount: (json['bounty_amount'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      lastSeenTime: json['last_seen_time'] as String,
      imageUrl: json['image_url'] as String,
      featureVector: (json['feature_vector'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      similarity: (json['similarity'] as num?)?.toDouble(),
      primaryColorHex: json['primary_color_hex'] as String?,
      patternId: json['pattern_id'] as String?,
    );

Map<String, dynamic> _$$MissingPetModelImplToJson(
        _$MissingPetModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'pet_name': instance.petName,
      'species': instance.species,
      'characteristics': instance.characteristics,
      'bounty_amount': instance.bountyAmount,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'last_seen_time': instance.lastSeenTime,
      'image_url': instance.imageUrl,
      'feature_vector': instance.featureVector,
      'status': instance.status,
      'created_at': instance.createdAt,
      'distance_meters': instance.distanceMeters,
      'similarity': instance.similarity,
      'primary_color_hex': instance.primaryColorHex,
      'pattern_id': instance.patternId,
    };
