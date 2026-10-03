// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audience_preview_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudiencePreviewResponse _$AudiencePreviewResponseFromJson(
  Map<String, dynamic> json,
) => AudiencePreviewResponse(
  audienceType: _audienceTypeFromJson(json['audienceType'] as String),
  audienceTargetId: json['audienceTargetId'] as String,
  count: (json['count'] as num).toInt(),
  exceedsCallerCap: json['exceedsCallerCap'] as bool,
  hardCap: (json['hardCap'] as num).toInt(),
);

Map<String, dynamic> _$AudiencePreviewResponseToJson(
  AudiencePreviewResponse instance,
) => <String, dynamic>{
  'audienceType': _audienceTypeToJson(instance.audienceType),
  'audienceTargetId': instance.audienceTargetId,
  'count': instance.count,
  'exceedsCallerCap': instance.exceedsCallerCap,
  'hardCap': instance.hardCap,
};
