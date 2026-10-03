// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_event_media_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicEventMediaResponse _$PublicEventMediaResponseFromJson(
  Map<String, dynamic> json,
) => PublicEventMediaResponse(
  id: json['id'] as String,
  mediaType: json['mediaType'] as String,
  url: json['url'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  streamUrl: json['streamUrl'] as String?,
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$PublicEventMediaResponseToJson(
  PublicEventMediaResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'mediaType': instance.mediaType,
  'url': instance.url,
  'thumbnailUrl': instance.thumbnailUrl,
  'streamUrl': instance.streamUrl,
  'aspectRatio': instance.aspectRatio,
  'sortOrder': instance.sortOrder,
  'createdAt': instance.createdAt,
};
