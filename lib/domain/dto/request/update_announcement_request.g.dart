// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_announcement_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateAnnouncementRequest _$UpdateAnnouncementRequestFromJson(
  Map<String, dynamic> json,
) => UpdateAnnouncementRequest(
  titleAr: json['titleAr'] as String?,
  titleEn: json['titleEn'] as String?,
  bodyAr: json['bodyAr'] as String?,
  bodyEn: json['bodyEn'] as String?,
  pinned: json['pinned'] as bool?,
  active: json['active'] as bool?,
  expiresAt: json['expiresAt'] as String?,
);

Map<String, dynamic> _$UpdateAnnouncementRequestToJson(
  UpdateAnnouncementRequest instance,
) => <String, dynamic>{
  'titleAr': ?instance.titleAr,
  'titleEn': ?instance.titleEn,
  'bodyAr': ?instance.bodyAr,
  'bodyEn': ?instance.bodyEn,
  'pinned': ?instance.pinned,
  'active': ?instance.active,
  'expiresAt': ?instance.expiresAt,
};
