// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchModelImpl _$$MatchModelImplFromJson(Map<String, dynamic> json) =>
    _$MatchModelImpl(
      id: json['id'] as String,
      petName: json['pet_name'] as String,
      species: json['species'] as String,
      characteristics: json['characteristics'] as Map<String, dynamic>,
      bountyAmount: (json['bounty_amount'] as num).toDouble(),
      lastSeenLocation: json['last_seen_location'] as String,
      lastSeenTime: json['last_seen_time'] as String,
      imageUrl: json['image_url'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$$MatchModelImplToJson(_$MatchModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pet_name': instance.petName,
      'species': instance.species,
      'characteristics': instance.characteristics,
      'bounty_amount': instance.bountyAmount,
      'last_seen_location': instance.lastSeenLocation,
      'last_seen_time': instance.lastSeenTime,
      'image_url': instance.imageUrl,
      'similarity': instance.similarity,
      'distance_meters': instance.distanceMeters,
      'status': instance.status,
    };
