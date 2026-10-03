// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_menu_section_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMenuSectionRequest _$UpdateMenuSectionRequestFromJson(
  Map<String, dynamic> json,
) => UpdateMenuSectionRequest(
  nameAr: json['nameAr'] as String?,
  nameEn: json['nameEn'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  active: json['active'] as bool?,
);

Map<String, dynamic> _$UpdateMenuSectionRequestToJson(
  UpdateMenuSectionRequest instance,
) => <String, dynamic>{
  'nameAr': ?instance.nameAr,
  'nameEn': ?instance.nameEn,
  'sortOrder': ?instance.sortOrder,
  'active': ?instance.active,
};
