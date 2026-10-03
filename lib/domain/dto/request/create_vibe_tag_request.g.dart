// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_vibe_tag_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateVibeTagRequest _$CreateVibeTagRequestFromJson(
  Map<String, dynamic> json,
) => CreateVibeTagRequest(
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  dimension: json['dimension'] as String,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateVibeTagRequestToJson(
  CreateVibeTagRequest instance,
) => <String, dynamic>{
  'code': instance.code,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'dimension': instance.dimension,
  'sortOrder': ?instance.sortOrder,
};
