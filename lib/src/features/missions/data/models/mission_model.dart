import 'package:freezed_annotation/freezed_annotation.dart';

part 'mission_model.freezed.dart';
part 'mission_model.g.dart';

@freezed
class MissionModel with _$MissionModel {
  const factory MissionModel({
    required String id,
    @JsonKey(name: 'hunter_id') required String hunterId,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'sighted_location') required String sightedLocation,
    @JsonKey(name: 'detected_species') required String detectedSpecies,
    @JsonKey(name: 'sighting_status') required String sightingStatus,
    @JsonKey(name: 'created_at') required String createdAt,
    String? notes,
  }) = _MissionModel;

  factory MissionModel.fromJson(Map<String, dynamic> json) =>
      _$MissionModelFromJson(json);
}

@freezed
class MissionAcceptResponse with _$MissionAcceptResponse {
  const factory MissionAcceptResponse({
    required String status,
    required String message,
    Map<String, dynamic>? data,
  }) = _MissionAcceptResponse;

  factory MissionAcceptResponse.fromJson(Map<String, dynamic> json) =>
      _$MissionAcceptResponseFromJson(json);
}
