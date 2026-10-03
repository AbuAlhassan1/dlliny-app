// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibe_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeTagDto _$VibeTagDtoFromJson(Map<String, dynamic> json) => VibeTagDto(
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  dimension: json['dimension'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

Map<String, dynamic> _$VibeTagDtoToJson(VibeTagDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'dimension': instance.dimension,
      'sortOrder': instance.sortOrder,
    };

UserVibeAffinityDto _$UserVibeAffinityDtoFromJson(Map<String, dynamic> json) =>
    UserVibeAffinityDto(
      tagCode: json['tagCode'] as String,
      nameAr: json['nameAr'] as String?,
      nameEn: json['nameEn'] as String?,
      dimension: json['dimension'] as String?,
      score: (json['score'] as num).toDouble(),
      sampleCount: (json['sampleCount'] as num).toInt(),
    );

Map<String, dynamic> _$UserVibeAffinityDtoToJson(
  UserVibeAffinityDto instance,
) => <String, dynamic>{
  'tagCode': instance.tagCode,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'dimension': instance.dimension,
  'score': instance.score,
  'sampleCount': instance.sampleCount,
};

MyVibeProfileResponse _$MyVibeProfileResponseFromJson(
  Map<String, dynamic> json,
) => MyVibeProfileResponse(
  needsOnboarding: json['needsOnboarding'] as bool,
  lovedTagCodes:
      (json['lovedTagCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  avoidedTagCodes:
      (json['avoidedTagCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  affinities:
      (json['affinities'] as List<dynamic>?)
          ?.map((e) => UserVibeAffinityDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$MyVibeProfileResponseToJson(
  MyVibeProfileResponse instance,
) => <String, dynamic>{
  'needsOnboarding': instance.needsOnboarding,
  'lovedTagCodes': instance.lovedTagCodes,
  'avoidedTagCodes': instance.avoidedTagCodes,
  'affinities': instance.affinities,
};
