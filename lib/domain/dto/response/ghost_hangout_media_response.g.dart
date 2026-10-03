// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ghost_hangout_media_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GhostHangoutMediaResponse _$GhostHangoutMediaResponseFromJson(
  Map<String, dynamic> json,
) => GhostHangoutMediaResponse(
  id: json['id'] as String,
  hangoutId: json['hangoutId'] as String,
  url: json['url'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  streamUrl: json['streamUrl'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$GhostHangoutMediaResponseToJson(
  GhostHangoutMediaResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'hangoutId': instance.hangoutId,
  'url': instance.url,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': instance.aspectRatio,
  'thumbnailUrl': instance.thumbnailUrl,
  'streamUrl': instance.streamUrl,
  'createdAt': instance.createdAt,
};
