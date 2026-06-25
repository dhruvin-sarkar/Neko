// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CatDocumentImpl _$$CatDocumentImplFromJson(Map<String, dynamic> json) =>
    _$CatDocumentImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      storageUrl: json['storageUrl'] as String,
      uploadedAt: const TimestampConverter().fromJson(json['uploadedAt']),
    );

Map<String, dynamic> _$$CatDocumentImplToJson(_$CatDocumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'storageUrl': instance.storageUrl,
      'uploadedAt': const TimestampConverter().toJson(instance.uploadedAt),
    };
