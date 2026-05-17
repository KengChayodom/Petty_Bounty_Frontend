import 'package:freezed_annotation/freezed_annotation.dart';

part 'sighting_model.freezed.dart';
part 'sighting_model.g.dart';

@freezed
class SightingModel with _$SightingModel {
  const factory SightingModel({
    required String id,
    required String hunterId,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'sighted_location') required String sightedLocation,
    @JsonKey(name: 'detected_species') required String detectedSpecies,
    @JsonKey(name: 'feature_vector') required List<double> featureVector,
    @JsonKey(name: 'action_type') required String actionType,
    @JsonKey(name: 'sighting_status') required String sightingStatus,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'distance_meters') double? distanceMeters,
    double? similarity,
  }) = _SightingModel;

  factory SightingModel.fromJson(Map<String, dynamic> json) =>
      _$SightingModelFromJson(json);
}

@freezed
class SightingCreateRequest with _$SightingCreateRequest {
  const factory SightingCreateRequest({
    required String hunterId,
    @JsonKey(name: 'image_url') required String imageUrl,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'detected_species') required String detectedSpecies,
    List<double>? bbox,
    String? notes,
  }) = _SightingCreateRequest;

  factory SightingCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$SightingCreateRequestFromJson(json);
}
