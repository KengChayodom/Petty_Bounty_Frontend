import 'package:freezed_annotation/freezed_annotation.dart';

import 'match_model.dart';

part 'sighting_model.freezed.dart';
part 'sighting_model.g.dart';

@freezed
class SightingModel with _$SightingModel {
  const factory SightingModel({
    required String id,
    @JsonKey(name: 'hunter_id') required String hunterId,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'sighted_location') required String sightedLocation,
    @JsonKey(name: 'detected_species') required String detectedSpecies,
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
    @JsonKey(name: 'hunter_id') required String hunterId,
    @JsonKey(name: 'image_url') required String imageUrl,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'detected_species') required String detectedSpecies,
    // `bbox` is retained on the wire shape for backward compatibility with
    // existing generated code, but the backend no longer requires it (the
    // /analyze step caches the feature vector keyed by image_url). The
    // repository sends it as null.
    List<double>? bbox,
    String? notes,
  }) = _SightingCreateRequest;

  factory SightingCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$SightingCreateRequestFromJson(json);
}

/// Response wrapper for `POST /sightings/`.
///
/// The backend now bundles the freshly-inserted sighting AND the pgvector
/// matches in one payload (`data: { sighting, matches }`) so the client
/// doesn't need a follow-up `GET /sightings/{id}/matches` call.
///
/// Implemented as a plain Dart class (not Freezed) so adding this type
/// does NOT require running `build_runner` — the existing generated files
/// for the Freezed classes above remain valid.
class SightingSubmitResult {
  final SightingModel sighting;
  final List<MatchModel> matches;

  const SightingSubmitResult({
    required this.sighting,
    required this.matches,
  });

  factory SightingSubmitResult.fromJson(Map<String, dynamic> json) {
    return SightingSubmitResult(
      sighting: SightingModel.fromJson(
        json['sighting'] as Map<String, dynamic>,
      ),
      matches: (json['matches'] as List<dynamic>? ?? const [])
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
