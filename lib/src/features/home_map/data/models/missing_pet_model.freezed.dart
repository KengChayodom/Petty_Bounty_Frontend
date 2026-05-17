// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'missing_pet_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MissingPetModel _$MissingPetModelFromJson(Map<String, dynamic> json) {
  return _MissingPetModel.fromJson(json);
}

/// @nodoc
mixin _$MissingPetModel {
  String get id =>
      throw _privateConstructorUsedError; // @JsonKey(name: 'owner_id') required String ownerId,
  @JsonKey(name: 'owner_id')
  String? get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'pet_name')
  String get petName => throw _privateConstructorUsedError;
  String get species => throw _privateConstructorUsedError;
  Map<String, dynamic> get characteristics =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'bounty_amount')
  double get bountyAmount => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_seen_time')
  String get lastSeenTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'feature_vector')
  List<double>? get featureVector => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_meters')
  double? get distanceMeters => throw _privateConstructorUsedError;
  double? get similarity => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_color_hex')
  String? get primaryColorHex => throw _privateConstructorUsedError;
  @JsonKey(name: 'pattern_id')
  String? get patternId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MissingPetModelCopyWith<MissingPetModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MissingPetModelCopyWith<$Res> {
  factory $MissingPetModelCopyWith(
          MissingPetModel value, $Res Function(MissingPetModel) then) =
      _$MissingPetModelCopyWithImpl<$Res, MissingPetModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'pet_name') String petName,
      String species,
      Map<String, dynamic> characteristics,
      @JsonKey(name: 'bounty_amount') double bountyAmount,
      double latitude,
      double longitude,
      @JsonKey(name: 'last_seen_time') String lastSeenTime,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'feature_vector') List<double>? featureVector,
      String status,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'distance_meters') double? distanceMeters,
      double? similarity,
      @JsonKey(name: 'primary_color_hex') String? primaryColorHex,
      @JsonKey(name: 'pattern_id') String? patternId});
}

/// @nodoc
class _$MissingPetModelCopyWithImpl<$Res, $Val extends MissingPetModel>
    implements $MissingPetModelCopyWith<$Res> {
  _$MissingPetModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = freezed,
    Object? petName = null,
    Object? species = null,
    Object? characteristics = null,
    Object? bountyAmount = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? lastSeenTime = null,
    Object? imageUrl = null,
    Object? featureVector = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? distanceMeters = freezed,
    Object? similarity = freezed,
    Object? primaryColorHex = freezed,
    Object? patternId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      petName: null == petName
          ? _value.petName
          : petName // ignore: cast_nullable_to_non_nullable
              as String,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as String,
      characteristics: null == characteristics
          ? _value.characteristics
          : characteristics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      bountyAmount: null == bountyAmount
          ? _value.bountyAmount
          : bountyAmount // ignore: cast_nullable_to_non_nullable
              as double,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      lastSeenTime: null == lastSeenTime
          ? _value.lastSeenTime
          : lastSeenTime // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      featureVector: freezed == featureVector
          ? _value.featureVector
          : featureVector // ignore: cast_nullable_to_non_nullable
              as List<double>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      distanceMeters: freezed == distanceMeters
          ? _value.distanceMeters
          : distanceMeters // ignore: cast_nullable_to_non_nullable
              as double?,
      similarity: freezed == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double?,
      primaryColorHex: freezed == primaryColorHex
          ? _value.primaryColorHex
          : primaryColorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      patternId: freezed == patternId
          ? _value.patternId
          : patternId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MissingPetModelImplCopyWith<$Res>
    implements $MissingPetModelCopyWith<$Res> {
  factory _$$MissingPetModelImplCopyWith(_$MissingPetModelImpl value,
          $Res Function(_$MissingPetModelImpl) then) =
      __$$MissingPetModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'pet_name') String petName,
      String species,
      Map<String, dynamic> characteristics,
      @JsonKey(name: 'bounty_amount') double bountyAmount,
      double latitude,
      double longitude,
      @JsonKey(name: 'last_seen_time') String lastSeenTime,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'feature_vector') List<double>? featureVector,
      String status,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'distance_meters') double? distanceMeters,
      double? similarity,
      @JsonKey(name: 'primary_color_hex') String? primaryColorHex,
      @JsonKey(name: 'pattern_id') String? patternId});
}

/// @nodoc
class __$$MissingPetModelImplCopyWithImpl<$Res>
    extends _$MissingPetModelCopyWithImpl<$Res, _$MissingPetModelImpl>
    implements _$$MissingPetModelImplCopyWith<$Res> {
  __$$MissingPetModelImplCopyWithImpl(
      _$MissingPetModelImpl _value, $Res Function(_$MissingPetModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = freezed,
    Object? petName = null,
    Object? species = null,
    Object? characteristics = null,
    Object? bountyAmount = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? lastSeenTime = null,
    Object? imageUrl = null,
    Object? featureVector = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? distanceMeters = freezed,
    Object? similarity = freezed,
    Object? primaryColorHex = freezed,
    Object? patternId = freezed,
  }) {
    return _then(_$MissingPetModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      petName: null == petName
          ? _value.petName
          : petName // ignore: cast_nullable_to_non_nullable
              as String,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as String,
      characteristics: null == characteristics
          ? _value._characteristics
          : characteristics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      bountyAmount: null == bountyAmount
          ? _value.bountyAmount
          : bountyAmount // ignore: cast_nullable_to_non_nullable
              as double,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      lastSeenTime: null == lastSeenTime
          ? _value.lastSeenTime
          : lastSeenTime // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      featureVector: freezed == featureVector
          ? _value._featureVector
          : featureVector // ignore: cast_nullable_to_non_nullable
              as List<double>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      distanceMeters: freezed == distanceMeters
          ? _value.distanceMeters
          : distanceMeters // ignore: cast_nullable_to_non_nullable
              as double?,
      similarity: freezed == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double?,
      primaryColorHex: freezed == primaryColorHex
          ? _value.primaryColorHex
          : primaryColorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      patternId: freezed == patternId
          ? _value.patternId
          : patternId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MissingPetModelImpl implements _MissingPetModel {
  const _$MissingPetModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') this.ownerId,
      @JsonKey(name: 'pet_name') required this.petName,
      required this.species,
      required final Map<String, dynamic> characteristics,
      @JsonKey(name: 'bounty_amount') required this.bountyAmount,
      required this.latitude,
      required this.longitude,
      @JsonKey(name: 'last_seen_time') required this.lastSeenTime,
      @JsonKey(name: 'image_url') required this.imageUrl,
      @JsonKey(name: 'feature_vector') final List<double>? featureVector,
      required this.status,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'distance_meters') this.distanceMeters,
      this.similarity,
      @JsonKey(name: 'primary_color_hex') this.primaryColorHex,
      @JsonKey(name: 'pattern_id') this.patternId})
      : _characteristics = characteristics,
        _featureVector = featureVector;

  factory _$MissingPetModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MissingPetModelImplFromJson(json);

  @override
  final String id;
// @JsonKey(name: 'owner_id') required String ownerId,
  @override
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  @override
  @JsonKey(name: 'pet_name')
  final String petName;
  @override
  final String species;
  final Map<String, dynamic> _characteristics;
  @override
  Map<String, dynamic> get characteristics {
    if (_characteristics is EqualUnmodifiableMapView) return _characteristics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_characteristics);
  }

  @override
  @JsonKey(name: 'bounty_amount')
  final double bountyAmount;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey(name: 'last_seen_time')
  final String lastSeenTime;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final List<double>? _featureVector;
  @override
  @JsonKey(name: 'feature_vector')
  List<double>? get featureVector {
    final value = _featureVector;
    if (value == null) return null;
    if (_featureVector is EqualUnmodifiableListView) return _featureVector;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'distance_meters')
  final double? distanceMeters;
  @override
  final double? similarity;
  @override
  @JsonKey(name: 'primary_color_hex')
  final String? primaryColorHex;
  @override
  @JsonKey(name: 'pattern_id')
  final String? patternId;

  @override
  String toString() {
    return 'MissingPetModel(id: $id, ownerId: $ownerId, petName: $petName, species: $species, characteristics: $characteristics, bountyAmount: $bountyAmount, latitude: $latitude, longitude: $longitude, lastSeenTime: $lastSeenTime, imageUrl: $imageUrl, featureVector: $featureVector, status: $status, createdAt: $createdAt, distanceMeters: $distanceMeters, similarity: $similarity, primaryColorHex: $primaryColorHex, patternId: $patternId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MissingPetModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.petName, petName) || other.petName == petName) &&
            (identical(other.species, species) || other.species == species) &&
            const DeepCollectionEquality()
                .equals(other._characteristics, _characteristics) &&
            (identical(other.bountyAmount, bountyAmount) ||
                other.bountyAmount == bountyAmount) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.lastSeenTime, lastSeenTime) ||
                other.lastSeenTime == lastSeenTime) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._featureVector, _featureVector) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.distanceMeters, distanceMeters) ||
                other.distanceMeters == distanceMeters) &&
            (identical(other.similarity, similarity) ||
                other.similarity == similarity) &&
            (identical(other.primaryColorHex, primaryColorHex) ||
                other.primaryColorHex == primaryColorHex) &&
            (identical(other.patternId, patternId) ||
                other.patternId == patternId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ownerId,
      petName,
      species,
      const DeepCollectionEquality().hash(_characteristics),
      bountyAmount,
      latitude,
      longitude,
      lastSeenTime,
      imageUrl,
      const DeepCollectionEquality().hash(_featureVector),
      status,
      createdAt,
      distanceMeters,
      similarity,
      primaryColorHex,
      patternId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MissingPetModelImplCopyWith<_$MissingPetModelImpl> get copyWith =>
      __$$MissingPetModelImplCopyWithImpl<_$MissingPetModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MissingPetModelImplToJson(
      this,
    );
  }
}

abstract class _MissingPetModel implements MissingPetModel {
  const factory _MissingPetModel(
          {required final String id,
          @JsonKey(name: 'owner_id') final String? ownerId,
          @JsonKey(name: 'pet_name') required final String petName,
          required final String species,
          required final Map<String, dynamic> characteristics,
          @JsonKey(name: 'bounty_amount') required final double bountyAmount,
          required final double latitude,
          required final double longitude,
          @JsonKey(name: 'last_seen_time') required final String lastSeenTime,
          @JsonKey(name: 'image_url') required final String imageUrl,
          @JsonKey(name: 'feature_vector') final List<double>? featureVector,
          required final String status,
          @JsonKey(name: 'created_at') required final String createdAt,
          @JsonKey(name: 'distance_meters') final double? distanceMeters,
          final double? similarity,
          @JsonKey(name: 'primary_color_hex') final String? primaryColorHex,
          @JsonKey(name: 'pattern_id') final String? patternId}) =
      _$MissingPetModelImpl;

  factory _MissingPetModel.fromJson(Map<String, dynamic> json) =
      _$MissingPetModelImpl.fromJson;

  @override
  String get id;
  @override // @JsonKey(name: 'owner_id') required String ownerId,
  @JsonKey(name: 'owner_id')
  String? get ownerId;
  @override
  @JsonKey(name: 'pet_name')
  String get petName;
  @override
  String get species;
  @override
  Map<String, dynamic> get characteristics;
  @override
  @JsonKey(name: 'bounty_amount')
  double get bountyAmount;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  @JsonKey(name: 'last_seen_time')
  String get lastSeenTime;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  @JsonKey(name: 'feature_vector')
  List<double>? get featureVector;
  @override
  String get status;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'distance_meters')
  double? get distanceMeters;
  @override
  double? get similarity;
  @override
  @JsonKey(name: 'primary_color_hex')
  String? get primaryColorHex;
  @override
  @JsonKey(name: 'pattern_id')
  String? get patternId;
  @override
  @JsonKey(ignore: true)
  _$$MissingPetModelImplCopyWith<_$MissingPetModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
