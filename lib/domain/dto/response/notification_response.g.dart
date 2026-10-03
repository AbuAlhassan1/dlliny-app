// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationResponse _$NotificationResponseFromJson(
  Map<String, dynamic> json,
) => NotificationResponse(
  id: json['id'] as String,
  type: json['type'] as String,
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String,
  bodyAr: json['bodyAr'] as String,
  bodyEn: json['bodyEn'] as String,
  deepLink: json['deepLink'] as String?,
  actorId: json['actorId'] as String?,
  actorUsername: json['actorUsername'] as String?,
  actorAvatarUrl: json['actorAvatarUrl'] as String?,
  entityId: json['entityId'] as String?,
  entityType: json['entityType'] as String?,
  read: json['read'] as bool,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$NotificationResponseToJson(
  NotificationResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'bodyAr': instance.bodyAr,
  'bodyEn': instance.bodyEn,
  'deepLink': instance.deepLink,
  'actorId': instance.actorId,
  'actorUsername': instance.actorUsername,
  'actorAvatarUrl': instance.actorAvatarUrl,
  'entityId': instance.entityId,
  'entityType': instance.entityType,
  'read': instance.read,
  'createdAt': instance.createdAt,
};

UnreadCountResponse _$UnreadCountResponseFromJson(Map<String, dynamic> json) =>
    UnreadCountResponse(count: (json['count'] as num).toInt());

Map<String, dynamic> _$UnreadCountResponseToJson(
  UnreadCountResponse instance,
) => <String, dynamic>{'count': instance.count};
