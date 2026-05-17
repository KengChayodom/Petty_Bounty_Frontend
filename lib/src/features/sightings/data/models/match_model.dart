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
    @JsonKey(name: 'distance_meters') required double distanceMeters,
    required String status,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
}
