// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_announcement_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAnnouncementRequest _$CreateAnnouncementRequestFromJson(
  Map<String, dynamic> json,
) => CreateAnnouncementRequest(
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String?,
  bodyAr: json['bodyAr'] as String,
  bodyEn: json['bodyEn'] as String?,
  pinned: json['pinned'] as bool? ?? false,
  publishedAt: json['publishedAt'] as String?,
  expiresAt: json['expiresAt'] as String?,
);

Map<String, dynamic> _$CreateAnnouncementRequestToJson(
  CreateAnnouncementRequest instance,
) => <String, dynamic>{
  'titleAr': instance.titleAr,
  'titleEn': ?instance.titleEn,
  'bodyAr': instance.bodyAr,
  'bodyEn': ?instance.bodyEn,
  'pinned': instance.pinned,
  'publishedAt': ?instance.publishedAt,
  'expiresAt': ?instance.expiresAt,
};
