// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_gallery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessGalleryResponse _$BusinessGalleryResponseFromJson(
  Map<String, dynamic> json,
) => BusinessGalleryResponse(
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => GalleryPhotoDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  maxPhotos: (json['maxPhotos'] as num).toInt(),
  remaining: (json['remaining'] as num).toInt(),
  privacyHintTags:
      (json['privacyHintTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$BusinessGalleryResponseToJson(
  BusinessGalleryResponse instance,
) => <String, dynamic>{
  'photos': instance.photos.map((e) => e.toJson()).toList(),
  'maxPhotos': instance.maxPhotos,
  'remaining': instance.remaining,
  'privacyHintTags': instance.privacyHintTags,
};

GalleryUploadUrlResponse _$GalleryUploadUrlResponseFromJson(
  Map<String, dynamic> json,
) => GalleryUploadUrlResponse(
  uploadUrl: json['uploadUrl'] as String,
  key: json['key'] as String,
  expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
  maxBytes: (json['maxBytes'] as num).toInt(),
);

Map<String, dynamic> _$GalleryUploadUrlResponseToJson(
  GalleryUploadUrlResponse instance,
) => <String, dynamic>{
  'uploadUrl': instance.uploadUrl,
  'key': instance.key,
  'expiresInSeconds': instance.expiresInSeconds,
  'maxBytes': instance.maxBytes,
};
