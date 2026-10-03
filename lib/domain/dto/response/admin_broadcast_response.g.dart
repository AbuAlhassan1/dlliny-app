// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_broadcast_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminBroadcastResponse _$AdminBroadcastResponseFromJson(
  Map<String, dynamic> json,
) => AdminBroadcastResponse(
  id: json['id'] as String,
  sentByAdminId: json['sentByAdminId'] as String,
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String,
  bodyAr: json['bodyAr'] as String,
  bodyEn: json['bodyEn'] as String,
  deepLink: json['deepLink'] as String?,
  audienceType: _audienceTypeFromJson(json['audienceType'] as String),
  audienceTargetId: json['audienceTargetId'] as String,
  audienceCount: (json['audienceCount'] as num).toInt(),
  inAppSuccessCount: (json['inAppSuccessCount'] as num).toInt(),
  pushSuccessCount: (json['pushSuccessCount'] as num).toInt(),
  pushFailureCount: (json['pushFailureCount'] as num).toInt(),
  status: _statusFromJson(json['status'] as String),
  failureReason: json['failureReason'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$AdminBroadcastResponseToJson(
  AdminBroadcastResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'sentByAdminId': instance.sentByAdminId,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'bodyAr': instance.bodyAr,
  'bodyEn': instance.bodyEn,
  'deepLink': instance.deepLink,
  'audienceType': _audienceTypeToJson(instance.audienceType),
  'audienceTargetId': instance.audienceTargetId,
  'audienceCount': instance.audienceCount,
  'inAppSuccessCount': instance.inAppSuccessCount,
  'pushSuccessCount': instance.pushSuccessCount,
  'pushFailureCount': instance.pushFailureCount,
  'status': _statusToJson(instance.status),
  'failureReason': instance.failureReason,
  'createdAt': instance.createdAt.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
};
