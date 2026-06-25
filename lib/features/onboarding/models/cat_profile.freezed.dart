// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CatProfile _$CatProfileFromJson(Map<String, dynamic> json) {
  return _CatProfile.fromJson(json);
}

/// @nodoc
mixin _$CatProfile {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get breed => throw _privateConstructorUsedError;
  int get ageMonths => throw _privateConstructorUsedError;
  double get weightKg => throw _privateConstructorUsedError;
  String get colorType => throw _privateConstructorUsedError;
  String get activityLevel => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get birthday => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  int get dailyCalorieTarget => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CatProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CatProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CatProfileCopyWith<CatProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CatProfileCopyWith<$Res> {
  factory $CatProfileCopyWith(
    CatProfile value,
    $Res Function(CatProfile) then,
  ) = _$CatProfileCopyWithImpl<$Res, CatProfile>;
  @useResult
  $Res call({
    String id,
    String name,
    String breed,
    int ageMonths,
    double weightKg,
    String colorType,
    String activityLevel,
    @TimestampConverter() DateTime? birthday,
    String? photoUrl,
    int dailyCalorieTarget,
    @TimestampConverter() DateTime? createdAt,
  });
}

/// @nodoc
class _$CatProfileCopyWithImpl<$Res, $Val extends CatProfile>
    implements $CatProfileCopyWith<$Res> {
  _$CatProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CatProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? breed = null,
    Object? ageMonths = null,
    Object? weightKg = null,
    Object? colorType = null,
    Object? activityLevel = null,
    Object? birthday = freezed,
    Object? photoUrl = freezed,
    Object? dailyCalorieTarget = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            breed: null == breed
                ? _value.breed
                : breed // ignore: cast_nullable_to_non_nullable
                      as String,
            ageMonths: null == ageMonths
                ? _value.ageMonths
                : ageMonths // ignore: cast_nullable_to_non_nullable
                      as int,
            weightKg: null == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double,
            colorType: null == colorType
                ? _value.colorType
                : colorType // ignore: cast_nullable_to_non_nullable
                      as String,
            activityLevel: null == activityLevel
                ? _value.activityLevel
                : activityLevel // ignore: cast_nullable_to_non_nullable
                      as String,
            birthday: freezed == birthday
                ? _value.birthday
                : birthday // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            photoUrl: freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            dailyCalorieTarget: null == dailyCalorieTarget
                ? _value.dailyCalorieTarget
                : dailyCalorieTarget // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CatProfileImplCopyWith<$Res>
    implements $CatProfileCopyWith<$Res> {
  factory _$$CatProfileImplCopyWith(
    _$CatProfileImpl value,
    $Res Function(_$CatProfileImpl) then,
  ) = __$$CatProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String breed,
    int ageMonths,
    double weightKg,
    String colorType,
    String activityLevel,
    @TimestampConverter() DateTime? birthday,
    String? photoUrl,
    int dailyCalorieTarget,
    @TimestampConverter() DateTime? createdAt,
  });
}

/// @nodoc
class __$$CatProfileImplCopyWithImpl<$Res>
    extends _$CatProfileCopyWithImpl<$Res, _$CatProfileImpl>
    implements _$$CatProfileImplCopyWith<$Res> {
  __$$CatProfileImplCopyWithImpl(
    _$CatProfileImpl _value,
    $Res Function(_$CatProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CatProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? breed = null,
    Object? ageMonths = null,
    Object? weightKg = null,
    Object? colorType = null,
    Object? activityLevel = null,
    Object? birthday = freezed,
    Object? photoUrl = freezed,
    Object? dailyCalorieTarget = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CatProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        breed: null == breed
            ? _value.breed
            : breed // ignore: cast_nullable_to_non_nullable
                  as String,
        ageMonths: null == ageMonths
            ? _value.ageMonths
            : ageMonths // ignore: cast_nullable_to_non_nullable
                  as int,
        weightKg: null == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double,
        colorType: null == colorType
            ? _value.colorType
            : colorType // ignore: cast_nullable_to_non_nullable
                  as String,
        activityLevel: null == activityLevel
            ? _value.activityLevel
            : activityLevel // ignore: cast_nullable_to_non_nullable
                  as String,
        birthday: freezed == birthday
            ? _value.birthday
            : birthday // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        photoUrl: freezed == photoUrl
            ? _value.photoUrl
            : photoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        dailyCalorieTarget: null == dailyCalorieTarget
            ? _value.dailyCalorieTarget
            : dailyCalorieTarget // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CatProfileImpl extends _CatProfile {
  const _$CatProfileImpl({
    required this.id,
    required this.name,
    required this.breed,
    required this.ageMonths,
    required this.weightKg,
    required this.colorType,
    required this.activityLevel,
    @TimestampConverter() this.birthday,
    this.photoUrl,
    this.dailyCalorieTarget = 0,
    @TimestampConverter() this.createdAt,
  }) : super._();

  factory _$CatProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$CatProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String breed;
  @override
  final int ageMonths;
  @override
  final double weightKg;
  @override
  final String colorType;
  @override
  final String activityLevel;
  @override
  @TimestampConverter()
  final DateTime? birthday;
  @override
  final String? photoUrl;
  @override
  @JsonKey()
  final int dailyCalorieTarget;
  @override
  @TimestampConverter()
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CatProfile(id: $id, name: $name, breed: $breed, ageMonths: $ageMonths, weightKg: $weightKg, colorType: $colorType, activityLevel: $activityLevel, birthday: $birthday, photoUrl: $photoUrl, dailyCalorieTarget: $dailyCalorieTarget, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CatProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.breed, breed) || other.breed == breed) &&
            (identical(other.ageMonths, ageMonths) ||
                other.ageMonths == ageMonths) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.colorType, colorType) ||
                other.colorType == colorType) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            (identical(other.birthday, birthday) ||
                other.birthday == birthday) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.dailyCalorieTarget, dailyCalorieTarget) ||
                other.dailyCalorieTarget == dailyCalorieTarget) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    breed,
    ageMonths,
    weightKg,
    colorType,
    activityLevel,
    birthday,
    photoUrl,
    dailyCalorieTarget,
    createdAt,
  );

  /// Create a copy of CatProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CatProfileImplCopyWith<_$CatProfileImpl> get copyWith =>
      __$$CatProfileImplCopyWithImpl<_$CatProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CatProfileImplToJson(this);
  }
}

abstract class _CatProfile extends CatProfile {
  const factory _CatProfile({
    required final String id,
    required final String name,
    required final String breed,
    required final int ageMonths,
    required final double weightKg,
    required final String colorType,
    required final String activityLevel,
    @TimestampConverter() final DateTime? birthday,
    final String? photoUrl,
    final int dailyCalorieTarget,
    @TimestampConverter() final DateTime? createdAt,
  }) = _$CatProfileImpl;
  const _CatProfile._() : super._();

  factory _CatProfile.fromJson(Map<String, dynamic> json) =
      _$CatProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get breed;
  @override
  int get ageMonths;
  @override
  double get weightKg;
  @override
  String get colorType;
  @override
  String get activityLevel;
  @override
  @TimestampConverter()
  DateTime? get birthday;
  @override
  String? get photoUrl;
  @override
  int get dailyCalorieTarget;
  @override
  @TimestampConverter()
  DateTime? get createdAt;

  /// Create a copy of CatProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CatProfileImplCopyWith<_$CatProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
