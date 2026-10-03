// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BroadcastRequest _$BroadcastRequestFromJson(Map<String, dynamic> json) =>
    BroadcastRequest(
      audienceType: _audienceTypeFromJson(json['audienceType'] as String),
      audienceTargetId: json['audienceTargetId'] as String,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String,
      bodyAr: json['bodyAr'] as String,
      bodyEn: json['bodyEn'] as String,
      deepLink: json['deepLink'] as String?,
      confirm: json['confirm'] as bool? ?? false,
    );

Map<String, dynamic> _$BroadcastRequestToJson(BroadcastRequest instance) =>
    <String, dynamic>{
      'audienceType': _audienceTypeToJson(instance.audienceType),
      'audienceTargetId': instance.audienceTargetId,
      'titleAr': instance.titleAr,
      'titleEn': instance.titleEn,
      'bodyAr': instance.bodyAr,
      'bodyEn': instance.bodyEn,
      'deepLink': ?instance.deepLink,
      'confirm': instance.confirm,
    };
