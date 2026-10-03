// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibe_tag_catalog_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeTagCatalogResponse _$VibeTagCatalogResponseFromJson(
  Map<String, dynamic> json,
) => VibeTagCatalogResponse(
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  dimension: json['dimension'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  active: json['active'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$VibeTagCatalogResponseToJson(
  VibeTagCatalogResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'dimension': instance.dimension,
  'sortOrder': instance.sortOrder,
  'active': instance.active,
  'createdAt': instance.createdAt.toIso8601String(),
};
