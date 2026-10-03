// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_perk_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeaturedPerkResponse _$FeaturedPerkResponseFromJson(
  Map<String, dynamic> json,
) => FeaturedPerkResponse(
  code: json['code'] as String,
  labelAr: json['labelAr'] as String?,
  labelEn: json['labelEn'] as String?,
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
);

Map<String, dynamic> _$FeaturedPerkResponseToJson(
  FeaturedPerkResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'labelAr': instance.labelAr,
  'labelEn': instance.labelEn,
  'descriptionAr': instance.descriptionAr,
  'descriptionEn': instance.descriptionEn,
};
