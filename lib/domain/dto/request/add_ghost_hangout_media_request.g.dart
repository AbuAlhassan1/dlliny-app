// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_ghost_hangout_media_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddGhostHangoutMediaRequest _$AddGhostHangoutMediaRequestFromJson(
  Map<String, dynamic> json,
) => AddGhostHangoutMediaRequest(
  key: json['key'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AddGhostHangoutMediaRequestToJson(
  AddGhostHangoutMediaRequest instance,
) => <String, dynamic>{
  'key': instance.key,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': ?instance.aspectRatio,
};
