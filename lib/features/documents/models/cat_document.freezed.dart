// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CatDocument _$CatDocumentFromJson(Map<String, dynamic> json) {
  return _CatDocument.fromJson(json);
}

/// @nodoc
mixin _$CatDocument {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get storageUrl => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get uploadedAt => throw _privateConstructorUsedError;

  /// Serializes this CatDocument to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CatDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CatDocumentCopyWith<CatDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CatDocumentCopyWith<$Res> {
  factory $CatDocumentCopyWith(
    CatDocument value,
    $Res Function(CatDocument) then,
  ) = _$CatDocumentCopyWithImpl<$Res, CatDocument>;
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    String storageUrl,
    @TimestampConverter() DateTime? uploadedAt,
  });
}

/// @nodoc
class _$CatDocumentCopyWithImpl<$Res, $Val extends CatDocument>
    implements $CatDocumentCopyWith<$Res> {
  _$CatDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CatDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? storageUrl = null,
    Object? uploadedAt = freezed,
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
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            storageUrl: null == storageUrl
                ? _value.storageUrl
                : storageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            uploadedAt: freezed == uploadedAt
                ? _value.uploadedAt
                : uploadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CatDocumentImplCopyWith<$Res>
    implements $CatDocumentCopyWith<$Res> {
  factory _$$CatDocumentImplCopyWith(
    _$CatDocumentImpl value,
    $Res Function(_$CatDocumentImpl) then,
  ) = __$$CatDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    String storageUrl,
    @TimestampConverter() DateTime? uploadedAt,
  });
}

/// @nodoc
class __$$CatDocumentImplCopyWithImpl<$Res>
    extends _$CatDocumentCopyWithImpl<$Res, _$CatDocumentImpl>
    implements _$$CatDocumentImplCopyWith<$Res> {
  __$$CatDocumentImplCopyWithImpl(
    _$CatDocumentImpl _value,
    $Res Function(_$CatDocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CatDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? storageUrl = null,
    Object? uploadedAt = freezed,
  }) {
    return _then(
      _$CatDocumentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        storageUrl: null == storageUrl
            ? _value.storageUrl
            : storageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        uploadedAt: freezed == uploadedAt
            ? _value.uploadedAt
            : uploadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CatDocumentImpl implements _CatDocument {
  const _$CatDocumentImpl({
    required this.id,
    required this.name,
    required this.type,
    required this.storageUrl,
    @TimestampConverter() this.uploadedAt,
  });

  factory _$CatDocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CatDocumentImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String type;
  @override
  final String storageUrl;
  @override
  @TimestampConverter()
  final DateTime? uploadedAt;

  @override
  String toString() {
    return 'CatDocument(id: $id, name: $name, type: $type, storageUrl: $storageUrl, uploadedAt: $uploadedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CatDocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.storageUrl, storageUrl) ||
                other.storageUrl == storageUrl) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, type, storageUrl, uploadedAt);

  /// Create a copy of CatDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CatDocumentImplCopyWith<_$CatDocumentImpl> get copyWith =>
      __$$CatDocumentImplCopyWithImpl<_$CatDocumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CatDocumentImplToJson(this);
  }
}

abstract class _CatDocument implements CatDocument {
  const factory _CatDocument({
    required final String id,
    required final String name,
    required final String type,
    required final String storageUrl,
    @TimestampConverter() final DateTime? uploadedAt,
  }) = _$CatDocumentImpl;

  factory _CatDocument.fromJson(Map<String, dynamic> json) =
      _$CatDocumentImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get type;
  @override
  String get storageUrl;
  @override
  @TimestampConverter()
  DateTime? get uploadedAt;

  /// Create a copy of CatDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CatDocumentImplCopyWith<_$CatDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
