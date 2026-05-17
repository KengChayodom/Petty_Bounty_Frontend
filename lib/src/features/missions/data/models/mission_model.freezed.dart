// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mission_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MissionModel _$MissionModelFromJson(Map<String, dynamic> json) {
  return _MissionModel.fromJson(json);
}

/// @nodoc
mixin _$MissionModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'hunter_id')
  String get hunterId => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'sighted_location')
  String get sightedLocation => throw _privateConstructorUsedError;
  @JsonKey(name: 'detected_species')
  String get detectedSpecies => throw _privateConstructorUsedError;
  @JsonKey(name: 'sighting_status')
  String get sightingStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MissionModelCopyWith<MissionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MissionModelCopyWith<$Res> {
  factory $MissionModelCopyWith(
          MissionModel value, $Res Function(MissionModel) then) =
      _$MissionModelCopyWithImpl<$Res, MissionModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'hunter_id') String hunterId,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'sighted_location') String sightedLocation,
      @JsonKey(name: 'detected_species') String detectedSpecies,
      @JsonKey(name: 'sighting_status') String sightingStatus,
      @JsonKey(name: 'created_at') String createdAt,
      String? notes});
}

/// @nodoc
class _$MissionModelCopyWithImpl<$Res, $Val extends MissionModel>
    implements $MissionModelCopyWith<$Res> {
  _$MissionModelCopyWithImpl(this._value, this._then);

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
    Object? sightingStatus = null,
    Object? createdAt = null,
    Object? notes = freezed,
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
      sightingStatus: null == sightingStatus
          ? _value.sightingStatus
          : sightingStatus // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MissionModelImplCopyWith<$Res>
    implements $MissionModelCopyWith<$Res> {
  factory _$$MissionModelImplCopyWith(
          _$MissionModelImpl value, $Res Function(_$MissionModelImpl) then) =
      __$$MissionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'hunter_id') String hunterId,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'sighted_location') String sightedLocation,
      @JsonKey(name: 'detected_species') String detectedSpecies,
      @JsonKey(name: 'sighting_status') String sightingStatus,
      @JsonKey(name: 'created_at') String createdAt,
      String? notes});
}

/// @nodoc
class __$$MissionModelImplCopyWithImpl<$Res>
    extends _$MissionModelCopyWithImpl<$Res, _$MissionModelImpl>
    implements _$$MissionModelImplCopyWith<$Res> {
  __$$MissionModelImplCopyWithImpl(
      _$MissionModelImpl _value, $Res Function(_$MissionModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hunterId = null,
    Object? imageUrl = null,
    Object? sightedLocation = null,
    Object? detectedSpecies = null,
    Object? sightingStatus = null,
    Object? createdAt = null,
    Object? notes = freezed,
  }) {
    return _then(_$MissionModelImpl(
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
      sightingStatus: null == sightingStatus
          ? _value.sightingStatus
          : sightingStatus // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MissionModelImpl implements _MissionModel {
  const _$MissionModelImpl(
      {required this.id,
      @JsonKey(name: 'hunter_id') required this.hunterId,
      @JsonKey(name: 'image_url') required this.imageUrl,
      @JsonKey(name: 'sighted_location') required this.sightedLocation,
      @JsonKey(name: 'detected_species') required this.detectedSpecies,
      @JsonKey(name: 'sighting_status') required this.sightingStatus,
      @JsonKey(name: 'created_at') required this.createdAt,
      this.notes});

  factory _$MissionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MissionModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'hunter_id')
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
  @override
  @JsonKey(name: 'sighting_status')
  final String sightingStatus;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  final String? notes;

  @override
  String toString() {
    return 'MissionModel(id: $id, hunterId: $hunterId, imageUrl: $imageUrl, sightedLocation: $sightedLocation, detectedSpecies: $detectedSpecies, sightingStatus: $sightingStatus, createdAt: $createdAt, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MissionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.hunterId, hunterId) ||
                other.hunterId == hunterId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.sightedLocation, sightedLocation) ||
                other.sightedLocation == sightedLocation) &&
            (identical(other.detectedSpecies, detectedSpecies) ||
                other.detectedSpecies == detectedSpecies) &&
            (identical(other.sightingStatus, sightingStatus) ||
                other.sightingStatus == sightingStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, hunterId, imageUrl,
      sightedLocation, detectedSpecies, sightingStatus, createdAt, notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MissionModelImplCopyWith<_$MissionModelImpl> get copyWith =>
      __$$MissionModelImplCopyWithImpl<_$MissionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MissionModelImplToJson(
      this,
    );
  }
}

abstract class _MissionModel implements MissionModel {
  const factory _MissionModel(
      {required final String id,
      @JsonKey(name: 'hunter_id') required final String hunterId,
      @JsonKey(name: 'image_url') required final String imageUrl,
      @JsonKey(name: 'sighted_location') required final String sightedLocation,
      @JsonKey(name: 'detected_species') required final String detectedSpecies,
      @JsonKey(name: 'sighting_status') required final String sightingStatus,
      @JsonKey(name: 'created_at') required final String createdAt,
      final String? notes}) = _$MissionModelImpl;

  factory _MissionModel.fromJson(Map<String, dynamic> json) =
      _$MissionModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'hunter_id')
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
  @JsonKey(name: 'sighting_status')
  String get sightingStatus;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$MissionModelImplCopyWith<_$MissionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MissionAcceptResponse _$MissionAcceptResponseFromJson(
    Map<String, dynamic> json) {
  return _MissionAcceptResponse.fromJson(json);
}

/// @nodoc
mixin _$MissionAcceptResponse {
  String get status => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MissionAcceptResponseCopyWith<MissionAcceptResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MissionAcceptResponseCopyWith<$Res> {
  factory $MissionAcceptResponseCopyWith(MissionAcceptResponse value,
          $Res Function(MissionAcceptResponse) then) =
      _$MissionAcceptResponseCopyWithImpl<$Res, MissionAcceptResponse>;
  @useResult
  $Res call({String status, String message, Map<String, dynamic>? data});
}

/// @nodoc
class _$MissionAcceptResponseCopyWithImpl<$Res,
        $Val extends MissionAcceptResponse>
    implements $MissionAcceptResponseCopyWith<$Res> {
  _$MissionAcceptResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? message = null,
    Object? data = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MissionAcceptResponseImplCopyWith<$Res>
    implements $MissionAcceptResponseCopyWith<$Res> {
  factory _$$MissionAcceptResponseImplCopyWith(
          _$MissionAcceptResponseImpl value,
          $Res Function(_$MissionAcceptResponseImpl) then) =
      __$$MissionAcceptResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, String message, Map<String, dynamic>? data});
}

/// @nodoc
class __$$MissionAcceptResponseImplCopyWithImpl<$Res>
    extends _$MissionAcceptResponseCopyWithImpl<$Res,
        _$MissionAcceptResponseImpl>
    implements _$$MissionAcceptResponseImplCopyWith<$Res> {
  __$$MissionAcceptResponseImplCopyWithImpl(_$MissionAcceptResponseImpl _value,
      $Res Function(_$MissionAcceptResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? message = null,
    Object? data = freezed,
  }) {
    return _then(_$MissionAcceptResponseImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MissionAcceptResponseImpl implements _MissionAcceptResponse {
  const _$MissionAcceptResponseImpl(
      {required this.status,
      required this.message,
      final Map<String, dynamic>? data})
      : _data = data;

  factory _$MissionAcceptResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MissionAcceptResponseImplFromJson(json);

  @override
  final String status;
  @override
  final String message;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'MissionAcceptResponse(status: $status, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MissionAcceptResponseImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, status, message, const DeepCollectionEquality().hash(_data));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MissionAcceptResponseImplCopyWith<_$MissionAcceptResponseImpl>
      get copyWith => __$$MissionAcceptResponseImplCopyWithImpl<
          _$MissionAcceptResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MissionAcceptResponseImplToJson(
      this,
    );
  }
}

abstract class _MissionAcceptResponse implements MissionAcceptResponse {
  const factory _MissionAcceptResponse(
      {required final String status,
      required final String message,
      final Map<String, dynamic>? data}) = _$MissionAcceptResponseImpl;

  factory _MissionAcceptResponse.fromJson(Map<String, dynamic> json) =
      _$MissionAcceptResponseImpl.fromJson;

  @override
  String get status;
  @override
  String get message;
  @override
  Map<String, dynamic>? get data;
  @override
  @JsonKey(ignore: true)
  _$$MissionAcceptResponseImplCopyWith<_$MissionAcceptResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
