// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_intent_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateIntentRequest _$UpdateIntentRequestFromJson(Map<String, dynamic> json) =>
    UpdateIntentRequest(
      labelAr: json['labelAr'] as String?,
      labelEn: json['labelEn'] as String?,
      color: json['color'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      active: json['active'] as bool?,
      vibeTagCodes: (json['vibeTagCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UpdateIntentRequestToJson(
  UpdateIntentRequest instance,
) => <String, dynamic>{
  'labelAr': ?instance.labelAr,
  'labelEn': ?instance.labelEn,
  'color': ?instance.color,
  'sortOrder': ?instance.sortOrder,
  'active': ?instance.active,
  'vibeTagCodes': ?instance.vibeTagCodes,
};
