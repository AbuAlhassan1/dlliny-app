// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_menu_section_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMenuSectionRequest _$CreateMenuSectionRequestFromJson(
  Map<String, dynamic> json,
) => CreateMenuSectionRequest(
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

Map<String, dynamic> _$CreateMenuSectionRequestToJson(
  CreateMenuSectionRequest instance,
) => <String, dynamic>{
  'nameAr': instance.nameAr,
  'nameEn': ?instance.nameEn,
  'sortOrder': instance.sortOrder,
};
