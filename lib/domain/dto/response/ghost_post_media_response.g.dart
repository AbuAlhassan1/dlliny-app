// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ghost_post_media_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GhostPostMediaResponse _$GhostPostMediaResponseFromJson(
  Map<String, dynamic> json,
) => GhostPostMediaResponse(
  id: json['id'] as String,
  postId: json['postId'] as String,
  url: json['url'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  streamUrl: json['streamUrl'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$GhostPostMediaResponseToJson(
  GhostPostMediaResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'url': instance.url,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': instance.aspectRatio,
  'thumbnailUrl': instance.thumbnailUrl,
  'streamUrl': instance.streamUrl,
  'createdAt': instance.createdAt,
};
