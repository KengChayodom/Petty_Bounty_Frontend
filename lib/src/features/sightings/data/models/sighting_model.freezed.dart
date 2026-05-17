// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sighting_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SightingModel _$SightingModelFromJson(Map<String, dynamic> json) {
  return _SightingModel.fromJson(json);
}

/// @nodoc
mixin _$SightingModel {
  String get id => throw _privateConstructorUsedError;
  String get hunterId => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'sighted_location')
  String get sightedLocation => throw _privateConstructorUsedError;
  @JsonKey(name: 'detected_species')
  String get detectedSpecies => throw _privateConstructorUsedError;
  @JsonKey(name: 'feature_vector')
  List<double> get featureVector => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_type')
  String get actionType => throw _privateConstructorUsedError;
  @JsonKey(name: 'sighting_status')
  String get sightingStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_meters')
  double? get distanceMeters => throw _privateConstructorUsedError;
  double? get similarity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SightingModelCopyWith<SightingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SightingModelCopyWith<$Res> {
  factory $SightingModelCopyWith(
          SightingModel value, $Res Function(SightingModel) then) =
      _$SightingModelCopyWithImpl<$Res, SightingModel>;
  @useResult
  $Res call(
      {String id,
      String hunterId,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'sighted_location') String sightedLocation,
      @JsonKey(name: 'detected_species') String detectedSpecies,
      @JsonKey(name: 'feature_vector') List<double> featureVector,
      @JsonKey(name: 'action_type') String actionType,
      @JsonKey(name: 'sighting_status') String sightingStatus,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'distance_meters') double? distanceMeters,
      double? similarity});
}

/// @nodoc
class _$SightingModelCopyWithImpl<$Res, $Val extends SightingModel>
    implements $SightingModelCopyWith<$Res> {
  _$SightingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hunterId = null,
    Object? imageUrl = null,
    Object? sightedLocation = null,
    Object? detectedSpecies = null,
    Object? featureVector = null,
    Object? actionType = null,
    Object? sightingStatus = null,
    Object? createdAt = null,
    Object? distanceMeters = freezed,
    Object? similarity = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hunterId: null == hunterId
          ? _value.hunterId
          : hunterId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      sightedLocation: null == sightedLocation
          ? _value.sightedLocation
          : sightedLocation // ignore: cast_nullable_to_non_nullable
              as String,
      detectedSpecies: null == detectedSpecies
          ? _value.detectedSpecies
          : detectedSpecies // ignore: cast_nullable_to_non_nullable
              as String,
      featureVector: null == featureVector
          ? _value.featureVector
          : featureVector // ignore: cast_nullable_to_non_nullable
              as List<double>,
      actionType: null == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String,
      sightingStatus: null == sightingStatus
          ? _value.sightingStatus
          : sightingStatus // ignore: cast_nullable_to_non_nullable
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SightingModelImplCopyWith<$Res>
    implements $SightingModelCopyWith<$Res> {
  factory _$$SightingModelImplCopyWith(
          _$SightingModelImpl value, $Res Function(_$SightingModelImpl) then) =
      __$$SightingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String hunterId,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'sighted_location') String sightedLocation,
      @JsonKey(name: 'detected_species') String detectedSpecies,
      @JsonKey(name: 'feature_vector') List<double> featureVector,
      @JsonKey(name: 'action_type') String actionType,
      @JsonKey(name: 'sighting_status') String sightingStatus,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'distance_meters') double? distanceMeters,
      double? similarity});
}

/// @nodoc
class __$$SightingModelImplCopyWithImpl<$Res>
    extends _$SightingModelCopyWithImpl<$Res, _$SightingModelImpl>
    implements _$$SightingModelImplCopyWith<$Res> {
  __$$SightingModelImplCopyWithImpl(
      _$SightingModelImpl _value, $Res Function(_$SightingModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hunterId = null,
    Object? imageUrl = null,
    Object? sightedLocation = null,
    Object? detectedSpecies = null,
    Object? featureVector = null,
    Object? actionType = null,
    Object? sightingStatus = null,
    Object? createdAt = null,
    Object? distanceMeters = freezed,
    Object? similarity = freezed,
  }) {
    return _then(_$SightingModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hunterId: null == hunterId
          ? _value.hunterId
          : hunterId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      sightedLocation: null == sightedLocation
          ? _value.sightedLocation
          : sightedLocation // ignore: cast_nullable_to_non_nullable
              as String,
      detectedSpecies: null == detectedSpecies
          ? _value.detectedSpecies
          : detectedSpecies // ignore: cast_nullable_to_non_nullable
              as String,
      featureVector: null == featureVector
          ? _value._featureVector
          : featureVector // ignore: cast_nullable_to_non_nullable
              as List<double>,
      actionType: null == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String,
      sightingStatus: null == sightingStatus
          ? _value.sightingStatus
          : sightingStatus // ignore: cast_nullable_to_non_nullable
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SightingModelImpl implements _SightingModel {
  const _$SightingModelImpl(
      {required this.id,
      required this.hunterId,
      @JsonKey(name: 'image_url') required this.imageUrl,
      @JsonKey(name: 'sighted_location') required this.sightedLocation,
      @JsonKey(name: 'detected_species') required this.detectedSpecies,
      @JsonKey(name: 'feature_vector')
      required final List<double> featureVector,
      @JsonKey(name: 'action_type') required this.actionType,
      @JsonKey(name: 'sighting_status') required this.sightingStatus,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'distance_meters') this.distanceMeters,
      this.similarity})
      : _featureVector = featureVector;

  factory _$SightingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SightingModelImplFromJson(json);

  @override
  final String id;
  @override
  final String hunterId;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @override
  @JsonKey(name: 'sighted_location')
  final String sightedLocation;
  @override
  @JsonKey(name: 'detected_species')
  final String detectedSpecies;
  final List<double> _featureVector;
  @override
  @JsonKey(name: 'feature_vector')
  List<double> get featureVector {
    if (_featureVector is EqualUnmodifiableListView) return _featureVector;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_featureVector);
  }

  @override
  @JsonKey(name: 'action_type')
  final String actionType;
  @override
  @JsonKey(name: 'sighting_status')
  final String sightingStatus;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'distance_meters')
  final double? distanceMeters;
  @override
  final double? similarity;

  @override
  String toString() {
    return 'SightingModel(id: $id, hunterId: $hunterId, imageUrl: $imageUrl, sightedLocation: $sightedLocation, detectedSpecies: $detectedSpecies, featureVector: $featureVector, actionType: $actionType, sightingStatus: $sightingStatus, createdAt: $createdAt, distanceMeters: $distanceMeters, similarity: $similarity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SightingModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.hunterId, hunterId) ||
                other.hunterId == hunterId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.sightedLocation, sightedLocation) ||
                other.sightedLocation == sightedLocation) &&
            (identical(other.detectedSpecies, detectedSpecies) ||
                other.detectedSpecies == detectedSpecies) &&
            const DeepCollectionEquality()
                .equals(other._featureVector, _featureVector) &&
            (identical(other.actionType, actionType) ||
                other.actionType == actionType) &&
            (identical(other.sightingStatus, sightingStatus) ||
                other.sightingStatus == sightingStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.distanceMeters, distanceMeters) ||
                other.distanceMeters == distanceMeters) &&
            (identical(other.similarity, similarity) ||
                other.similarity == similarity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      hunterId,
      imageUrl,
      sightedLocation,
      detectedSpecies,
      const DeepCollectionEquality().hash(_featureVector),
      actionType,
      sightingStatus,
      createdAt,
      distanceMeters,
      similarity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SightingModelImplCopyWith<_$SightingModelImpl> get copyWith =>
      __$$SightingModelImplCopyWithImpl<_$SightingModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SightingModelImplToJson(
      this,
    );
  }
}

abstract class _SightingModel implements SightingModel {
  const factory _SightingModel(
      {required final String id,
      required final String hunterId,
      @JsonKey(name: 'image_url') required final String imageUrl,
      @JsonKey(name: 'sighted_location') required final String sightedLocation,
      @JsonKey(name: 'detected_species') required final String detectedSpecies,
      @JsonKey(name: 'feature_vector')
      required final List<double> featureVector,
      @JsonKey(name: 'action_type') required final String actionType,
      @JsonKey(name: 'sighting_status') required final String sightingStatus,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'distance_meters') final double? distanceMeters,
      final double? similarity}) = _$SightingModelImpl;

  factory _SightingModel.fromJson(Map<String, dynamic> json) =
      _$SightingModelImpl.fromJson;

  @override
  String get id;
  @override
  String get hunterId;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  @JsonKey(name: 'sighted_location')
  String get sightedLocation;
  @override
  @JsonKey(name: 'detected_species')
  String get detectedSpecies;
  @override
  @JsonKey(name: 'feature_vector')
  List<double> get featureVector;
  @override
  @JsonKey(name: 'action_type')
  String get actionType;
  @override
  @JsonKey(name: 'sighting_status')
  String get sightingStatus;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'distance_meters')
  double? get distanceMeters;
  @override
  double? get similarity;
  @override
  @JsonKey(ignore: true)
  _$$SightingModelImplCopyWith<_$SightingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SightingCreateRequest _$SightingCreateRequestFromJson(
    Map<String, dynamic> json) {
  return _SightingCreateRequest.fromJson(json);
}

/// @nodoc
mixin _$SightingCreateRequest {
  String get hunterId => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'detected_species')
  String get detectedSpecies => throw _privateConstructorUsedError;
  List<double>? get bbox => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SightingCreateRequestCopyWith<SightingCreateRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SightingCreateRequestCopyWith<$Res> {
  factory $SightingCreateRequestCopyWith(SightingCreateRequest value,
          $Res Function(SightingCreateRequest) then) =
      _$SightingCreateRequestCopyWithImpl<$Res, SightingCreateRequest>;
  @useResult
  $Res call(
      {String hunterId,
      @JsonKey(name: 'image_url') String imageUrl,
      double latitude,
      double longitude,
      @JsonKey(name: 'detected_species') String detectedSpecies,
      List<double>? bbox,
      String? notes});
}

/// @nodoc
class _$SightingCreateRequestCopyWithImpl<$Res,
        $Val extends SightingCreateRequest>
    implements $SightingCreateRequestCopyWith<$Res> {
  _$SightingCreateRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hunterId = null,
    Object? imageUrl = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? detectedSpecies = null,
    Object? bbox = freezed,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      hunterId: null == hunterId
          ? _value.hunterId
          : hunterId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      detectedSpecies: null == detectedSpecies
          ? _value.detectedSpecies
          : detectedSpecies // ignore: cast_nullable_to_non_nullable
              as String,
      bbox: freezed == bbox
          ? _value.bbox
          : bbox // ignore: cast_nullable_to_non_nullable
              as List<double>?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SightingCreateRequestImplCopyWith<$Res>
    implements $SightingCreateRequestCopyWith<$Res> {
  factory _$$SightingCreateRequestImplCopyWith(
          _$SightingCreateRequestImpl value,
          $Res Function(_$SightingCreateRequestImpl) then) =
      __$$SightingCreateRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String hunterId,
      @JsonKey(name: 'image_url') String imageUrl,
      double latitude,
      double longitude,
      @JsonKey(name: 'detected_species') String detectedSpecies,
      List<double>? bbox,
      String? notes});
}

/// @nodoc
class __$$SightingCreateRequestImplCopyWithImpl<$Res>
    extends _$SightingCreateRequestCopyWithImpl<$Res,
        _$SightingCreateRequestImpl>
    implements _$$SightingCreateRequestImplCopyWith<$Res> {
  __$$SightingCreateRequestImplCopyWithImpl(_$SightingCreateRequestImpl _value,
      $Res Function(_$SightingCreateRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hunterId = null,
    Object? imageUrl = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? detectedSpecies = null,
    Object? bbox = freezed,
    Object? notes = freezed,
  }) {
    return _then(_$SightingCreateRequestImpl(
      hunterId: null == hunterId
          ? _value.hunterId
          : hunterId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      detectedSpecies: null == detectedSpecies
          ? _value.detectedSpecies
          : detectedSpecies // ignore: cast_nullable_to_non_nullable
              as String,
      bbox: freezed == bbox
          ? _value._bbox
          : bbox // ignore: cast_nullable_to_non_nullable
              as List<double>?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SightingCreateRequestImpl implements _SightingCreateRequest {
  const _$SightingCreateRequestImpl(
      {required this.hunterId,
      @JsonKey(name: 'image_url') required this.imageUrl,
      required this.latitude,
      required this.longitude,
      @JsonKey(name: 'detected_species') required this.detectedSpecies,
      final List<double>? bbox,
      this.notes})
      : _bbox = bbox;

  factory _$SightingCreateRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SightingCreateRequestImplFromJson(json);

  @override
  final String hunterId;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey(name: 'detected_species')
  final String detectedSpecies;
  final List<double>? _bbox;
  @override
  List<double>? get bbox {
    final value = _bbox;
    if (value == null) return null;
    if (_bbox is EqualUnmodifiableListView) return _bbox;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? notes;

  @override
  String toString() {
    return 'SightingCreateRequest(hunterId: $hunterId, imageUrl: $imageUrl, latitude: $latitude, longitude: $longitude, detectedSpecies: $detectedSpecies, bbox: $bbox, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SightingCreateRequestImpl &&
            (identical(other.hunterId, hunterId) ||
                other.hunterId == hunterId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.detectedSpecies, detectedSpecies) ||
                other.detectedSpecies == detectedSpecies) &&
            const DeepCollectionEquality().equals(other._bbox, _bbox) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      hunterId,
      imageUrl,
      latitude,
      longitude,
      detectedSpecies,
      const DeepCollectionEquality().hash(_bbox),
      notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SightingCreateRequestImplCopyWith<_$SightingCreateRequestImpl>
      get copyWith => __$$SightingCreateRequestImplCopyWithImpl<
          _$SightingCreateRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SightingCreateRequestImplToJson(
      this,
    );
  }
}

abstract class _SightingCreateRequest implements SightingCreateRequest {
  const factory _SightingCreateRequest(
      {required final String hunterId,
      @JsonKey(name: 'image_url') required final String imageUrl,
      required final double latitude,
      required final double longitude,
      @JsonKey(name: 'detected_species') required final String detectedSpecies,
      final List<double>? bbox,
      final String? notes}) = _$SightingCreateRequestImpl;

  factory _SightingCreateRequest.fromJson(Map<String, dynamic> json) =
      _$SightingCreateRequestImpl.fromJson;

  @override
  String get hunterId;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  @JsonKey(name: 'detected_species')
  String get detectedSpecies;
  @override
  List<double>? get bbox;
  @override
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$SightingCreateRequestImplCopyWith<_$SightingCreateRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}
