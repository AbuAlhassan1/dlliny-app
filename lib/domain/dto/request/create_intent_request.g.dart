// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_intent_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateIntentRequest _$CreateIntentRequestFromJson(Map<String, dynamic> json) =>
    CreateIntentRequest(
      code: json['code'] as String,
      labelAr: json['labelAr'] as String,
      labelEn: json['labelEn'] as String,
      color: json['color'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      active: json['active'] as bool?,
      vibeTagCodes: (json['vibeTagCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateIntentRequestToJson(
  CreateIntentRequest instance,
) => <String, dynamic>{
  'code': instance.code,
  'labelAr': instance.labelAr,
  'labelEn': instance.labelEn,
  'color': ?instance.color,
  'sortOrder': ?instance.sortOrder,
  'active': ?instance.active,
  'vibeTagCodes': ?instance.vibeTagCodes,
};
