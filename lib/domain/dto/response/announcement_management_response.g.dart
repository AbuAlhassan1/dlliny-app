// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_management_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncementResponse _$AnnouncementResponseFromJson(
  Map<String, dynamic> json,
) => AnnouncementResponse(
  id: json['id'] as String,
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String?,
  bodyAr: json['bodyAr'] as String,
  bodyEn: json['bodyEn'] as String?,
  pinned: json['pinned'] as bool,
  active: json['active'] as bool,
  publishedAt: json['publishedAt'] as String?,
  expiresAt: json['expiresAt'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$AnnouncementResponseToJson(
  AnnouncementResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'bodyAr': instance.bodyAr,
  'bodyEn': instance.bodyEn,
  'pinned': instance.pinned,
  'active': instance.active,
  'publishedAt': instance.publishedAt,
  'expiresAt': instance.expiresAt,
  'createdAt': instance.createdAt,
};
