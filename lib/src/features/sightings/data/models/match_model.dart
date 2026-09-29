import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @JsonKey(name: 'pet_name') required String petName,
    required String species,
    required Map<String, dynamic> characteristics,
    @JsonKey(name: 'bounty_amount') required double bountyAmount,
    @JsonKey(name: 'last_seen_location') required String lastSeenLocation,
    @JsonKey(name: 'last_seen_time') required String lastSeenTime,
    @JsonKey(name: 'image_url') required String imageUrl,
    required double similarity,
    // The backend's own 1 to 3 rating, from the score that ordered the list.
    // Absent from a backend that predates it. See MatchStars.stars.
    @JsonKey(name: 'match_stars') int? matchStars,
    @JsonKey(name: 'distance_meters') required double distanceMeters,
    required String status,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
}

extension MatchStars on MatchModel {
  /// Stars to draw, 1 to 3.
  ///
  /// The backend rates each card from the same score that decided the order, so
  /// the stars can never contradict it. `similarity` is the CLIP cosine, which
  /// is on another scale than the ranking, and drawing stars from it is what
  /// once put a 2-star card above a 3-star one. It is only the fallback for a
  /// backend that does not send `match_stars` yet.
  int get stars {
    final rated = matchStars;
    if (rated != null) return rated.clamp(1, 3);
    if (similarity >= 0.9) return 3;
    if (similarity >= 0.7) return 2;
    return 1;
  }
}
