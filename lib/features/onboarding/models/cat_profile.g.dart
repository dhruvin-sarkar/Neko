// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CatProfileImpl _$$CatProfileImplFromJson(Map<String, dynamic> json) =>
    _$CatProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String,
      ageMonths: (json['ageMonths'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      colorType: json['colorType'] as String,
      activityLevel: json['activityLevel'] as String,
      birthday: const TimestampConverter().fromJson(json['birthday']),
      photoUrl: json['photoUrl'] as String?,
      dailyCalorieTarget: (json['dailyCalorieTarget'] as num?)?.toInt() ?? 0,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$$CatProfileImplToJson(_$CatProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'breed': instance.breed,
      'ageMonths': instance.ageMonths,
      'weightKg': instance.weightKg,
      'colorType': instance.colorType,
      'activityLevel': instance.activityLevel,
      'birthday': const TimestampConverter().toJson(instance.birthday),
      'photoUrl': instance.photoUrl,
      'dailyCalorieTarget': instance.dailyCalorieTarget,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
