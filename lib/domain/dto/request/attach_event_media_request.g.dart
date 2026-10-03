// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attach_event_media_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachEventMediaRequest _$AttachEventMediaRequestFromJson(
  Map<String, dynamic> json,
) => AttachEventMediaRequest(
  mediaType: json['mediaType'] as String,
  key: json['key'] as String,
  thumbnailKey: json['thumbnailKey'] as String?,
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$AttachEventMediaRequestToJson(
  AttachEventMediaRequest instance,
) => <String, dynamic>{
  'mediaType': instance.mediaType,
  'key': instance.key,
  'thumbnailKey': ?instance.thumbnailKey,
  'aspectRatio': ?instance.aspectRatio,
  'sortOrder': ?instance.sortOrder,
};
