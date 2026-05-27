// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) {
  return _MatchModel.fromJson(json);
}

/// @nodoc
mixin _$MatchModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'pet_name')
  String get petName => throw _privateConstructorUsedError;
  String get species => throw _privateConstructorUsedError;
  Map<String, dynamic> get characteristics =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'bounty_amount')
  double get bountyAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_seen_location')
  String get lastSeenLocation => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_seen_time')
  String get lastSeenTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  double get similarity => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_meters')
  double get distanceMeters => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MatchModelCopyWith<MatchModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchModelCopyWith<$Res> {
  factory $MatchModelCopyWith(
          MatchModel value, $Res Function(MatchModel) then) =
      _$MatchModelCopyWithImpl<$Res, MatchModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'pet_name') String petName,
      String species,
      Map<String, dynamic> characteristics,
      @JsonKey(name: 'bounty_amount') double bountyAmount,
      @JsonKey(name: 'last_seen_location') String lastSeenLocation,
      @JsonKey(name: 'last_seen_time') String lastSeenTime,
      @JsonKey(name: 'image_url') String imageUrl,
      double similarity,
      @JsonKey(name: 'distance_meters') double distanceMeters,
      String status});
}

/// @nodoc
class _$MatchModelCopyWithImpl<$Res, $Val extends MatchModel>
    implements $MatchModelCopyWith<$Res> {
  _$MatchModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petName = null,
    Object? species = null,
    Object? characteristics = null,
    Object? bountyAmount = null,
    Object? lastSeenLocation = null,
    Object? lastSeenTime = null,
    Object? imageUrl = null,
    Object? similarity = null,
    Object? distanceMeters = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      lastSeenLocation: null == lastSeenLocation
          ? _value.lastSeenLocation
          : lastSeenLocation // ignore: cast_nullable_to_non_nullable
              as String,
      lastSeenTime: null == lastSeenTime
          ? _value.lastSeenTime
          : lastSeenTime // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      similarity: null == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double,
      distanceMeters: null == distanceMeters
          ? _value.distanceMeters
          : distanceMeters // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchModelImplCopyWith<$Res>
    implements $MatchModelCopyWith<$Res> {
  factory _$$MatchModelImplCopyWith(
          _$MatchModelImpl value, $Res Function(_$MatchModelImpl) then) =
      __$$MatchModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'pet_name') String petName,
      String species,
      Map<String, dynamic> characteristics,
      @JsonKey(name: 'bounty_amount') double bountyAmount,
      @JsonKey(name: 'last_seen_location') String lastSeenLocation,
      @JsonKey(name: 'last_seen_time') String lastSeenTime,
      @JsonKey(name: 'image_url') String imageUrl,
      double similarity,
      @JsonKey(name: 'distance_meters') double distanceMeters,
      String status});
}

/// @nodoc
class __$$MatchModelImplCopyWithImpl<$Res>
    extends _$MatchModelCopyWithImpl<$Res, _$MatchModelImpl>
    implements _$$MatchModelImplCopyWith<$Res> {
  __$$MatchModelImplCopyWithImpl(
      _$MatchModelImpl _value, $Res Function(_$MatchModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petName = null,
    Object? species = null,
    Object? characteristics = null,
    Object? bountyAmount = null,
    Object? lastSeenLocation = null,
    Object? lastSeenTime = null,
    Object? imageUrl = null,
    Object? similarity = null,
    Object? distanceMeters = null,
    Object? status = null,
  }) {
    return _then(_$MatchModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      lastSeenLocation: null == lastSeenLocation
          ? _value.lastSeenLocation
          : lastSeenLocation // ignore: cast_nullable_to_non_nullable
              as String,
      lastSeenTime: null == lastSeenTime
          ? _value.lastSeenTime
          : lastSeenTime // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      similarity: null == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double,
      distanceMeters: null == distanceMeters
          ? _value.distanceMeters
          : distanceMeters // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchModelImpl implements _MatchModel {
  const _$MatchModelImpl(
      {required this.id,
      @JsonKey(name: 'pet_name') required this.petName,
      required this.species,
      required final Map<String, dynamic> characteristics,
      @JsonKey(name: 'bounty_amount') required this.bountyAmount,
      @JsonKey(name: 'last_seen_location') required this.lastSeenLocation,
      @JsonKey(name: 'last_seen_time') required this.lastSeenTime,
      @JsonKey(name: 'image_url') required this.imageUrl,
      required this.similarity,
      @JsonKey(name: 'distance_meters') required this.distanceMeters,
      required this.status})
      : _characteristics = characteristics;

  factory _$MatchModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchModelImplFromJson(json);

  @override
  final String id;
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
  @JsonKey(name: 'last_seen_location')
  final String lastSeenLocation;
  @override
  @JsonKey(name: 'last_seen_time')
  final String lastSeenTime;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @override
  final double similarity;
  @override
  @JsonKey(name: 'distance_meters')
  final double distanceMeters;
  @override
  final String status;

  @override
  String toString() {
    return 'MatchModel(id: $id, petName: $petName, species: $species, characteristics: $characteristics, bountyAmount: $bountyAmount, lastSeenLocation: $lastSeenLocation, lastSeenTime: $lastSeenTime, imageUrl: $imageUrl, similarity: $similarity, distanceMeters: $distanceMeters, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.petName, petName) || other.petName == petName) &&
            (identical(other.species, species) || other.species == species) &&
            const DeepCollectionEquality()
                .equals(other._characteristics, _characteristics) &&
            (identical(other.bountyAmount, bountyAmount) ||
                other.bountyAmount == bountyAmount) &&
            (identical(other.lastSeenLocation, lastSeenLocation) ||
                other.lastSeenLocation == lastSeenLocation) &&
            (identical(other.lastSeenTime, lastSeenTime) ||
                other.lastSeenTime == lastSeenTime) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.similarity, similarity) ||
                other.similarity == similarity) &&
            (identical(other.distanceMeters, distanceMeters) ||
                other.distanceMeters == distanceMeters) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      petName,
      species,
      const DeepCollectionEquality().hash(_characteristics),
      bountyAmount,
      lastSeenLocation,
      lastSeenTime,
      imageUrl,
      similarity,
      distanceMeters,
      status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchModelImplCopyWith<_$MatchModelImpl> get copyWith =>
      __$$MatchModelImplCopyWithImpl<_$MatchModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchModelImplToJson(
      this,
    );
  }
}

abstract class _MatchModel implements MatchModel {
  const factory _MatchModel(
      {required final String id,
      @JsonKey(name: 'pet_name') required final String petName,
      required final String species,
      required final Map<String, dynamic> characteristics,
      @JsonKey(name: 'bounty_amount') required final double bountyAmount,
      @JsonKey(name: 'last_seen_location')
      required final String lastSeenLocation,
      @JsonKey(name: 'last_seen_time') required final String lastSeenTime,
      @JsonKey(name: 'image_url') required final String imageUrl,
      required final double similarity,
      @JsonKey(name: 'distance_meters') required final double distanceMeters,
      required final String status}) = _$MatchModelImpl;

  factory _MatchModel.fromJson(Map<String, dynamic> json) =
      _$MatchModelImpl.fromJson;

  @override
  String get id;
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
  @JsonKey(name: 'last_seen_location')
  String get lastSeenLocation;
  @override
  @JsonKey(name: 'last_seen_time')
  String get lastSeenTime;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  double get similarity;
  @override
  @JsonKey(name: 'distance_meters')
  double get distanceMeters;
  @override
  String get status;
  @override
  @JsonKey(ignore: true)
  _$$MatchModelImplCopyWith<_$MatchModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
