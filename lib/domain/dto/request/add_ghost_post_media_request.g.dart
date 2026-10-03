// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_ghost_post_media_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddGhostPostMediaRequest _$AddGhostPostMediaRequestFromJson(
  Map<String, dynamic> json,
) => AddGhostPostMediaRequest(
  key: json['key'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AddGhostPostMediaRequestToJson(
  AddGhostPostMediaRequest instance,
) => <String, dynamic>{
  'key': instance.key,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': ?instance.aspectRatio,
};
