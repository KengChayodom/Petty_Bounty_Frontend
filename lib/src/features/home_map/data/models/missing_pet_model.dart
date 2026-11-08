import 'package:freezed_annotation/freezed_annotation.dart';

part 'missing_pet_model.freezed.dart';
part 'missing_pet_model.g.dart';

@freezed
class MissingPetModel with _$MissingPetModel {
  const factory MissingPetModel({
    required String id,
    // @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'owner_id') String? ownerId,
    @JsonKey(name: 'pet_name') required String petName,
    required String species,
    required Map<String, dynamic> characteristics,
    @JsonKey(name: 'bounty_amount') required double bountyAmount,

    required double latitude,
    required double longitude,

    @JsonKey(name: 'last_seen_time') required String lastSeenTime,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'feature_vector') List<double>? featureVector,
    required String status,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'distance_meters') double? distanceMeters,
    double? similarity,
    @JsonKey(name: 'primary_color_hex') String? primaryColorHex,
  }) = _MissingPetModel;

  factory MissingPetModel.fromJson(Map<String, dynamic> json) =>
      _$MissingPetModelFromJson(json);
}
