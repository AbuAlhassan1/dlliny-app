// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_vibe_tag_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateVibeTagRequest _$UpdateVibeTagRequestFromJson(
  Map<String, dynamic> json,
) => UpdateVibeTagRequest(
  nameAr: json['nameAr'] as String?,
  nameEn: json['nameEn'] as String?,
  dimension: json['dimension'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  active: json['active'] as bool?,
);

Map<String, dynamic> _$UpdateVibeTagRequestToJson(
  UpdateVibeTagRequest instance,
) => <String, dynamic>{
  'nameAr': ?instance.nameAr,
  'nameEn': ?instance.nameEn,
  'dimension': ?instance.dimension,
  'sortOrder': ?instance.sortOrder,
  'active': ?instance.active,
};
