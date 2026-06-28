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

/// @nodoc
mixin _$CatDocument {
  String get path => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  DateTime? get savedAt => throw _privateConstructorUsedError;

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
    String path,
    String name,
    String type,
    int sizeBytes,
    DateTime? savedAt,
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
    Object? path = null,
    Object? name = null,
    Object? type = null,
    Object? sizeBytes = null,
    Object? savedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            savedAt: freezed == savedAt
                ? _value.savedAt
                : savedAt // ignore: cast_nullable_to_non_nullable
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
    String path,
    String name,
    String type,
    int sizeBytes,
    DateTime? savedAt,
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
    Object? path = null,
    Object? name = null,
    Object? type = null,
    Object? sizeBytes = null,
    Object? savedAt = freezed,
  }) {
    return _then(
      _$CatDocumentImpl(
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        savedAt: freezed == savedAt
            ? _value.savedAt
            : savedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$CatDocumentImpl implements _CatDocument {
  const _$CatDocumentImpl({
    required this.path,
    required this.name,
    required this.type,
    this.sizeBytes = 0,
    this.savedAt,
  });

  @override
  final String path;
  @override
  final String name;
  @override
  final String type;
  @override
  @JsonKey()
  final int sizeBytes;
  @override
  final DateTime? savedAt;

  @override
  String toString() {
    return 'CatDocument(path: $path, name: $name, type: $type, sizeBytes: $sizeBytes, savedAt: $savedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CatDocumentImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, path, name, type, sizeBytes, savedAt);

  /// Create a copy of CatDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CatDocumentImplCopyWith<_$CatDocumentImpl> get copyWith =>
      __$$CatDocumentImplCopyWithImpl<_$CatDocumentImpl>(this, _$identity);
}

abstract class _CatDocument implements CatDocument {
  const factory _CatDocument({
    required final String path,
    required final String name,
    required final String type,
    final int sizeBytes,
    final DateTime? savedAt,
  }) = _$CatDocumentImpl;

  @override
  String get path;
  @override
  String get name;
  @override
  String get type;
  @override
  int get sizeBytes;
  @override
  DateTime? get savedAt;

  /// Create a copy of CatDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CatDocumentImplCopyWith<_$CatDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
