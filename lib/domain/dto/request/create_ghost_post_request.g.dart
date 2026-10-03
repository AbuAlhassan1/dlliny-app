// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ghost_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGhostPostRequest _$CreateGhostPostRequestFromJson(
  Map<String, dynamic> json,
) => CreateGhostPostRequest(
  caption: json['caption'] as String?,
  media: (json['media'] as List<dynamic>?)
      ?.map((e) => GhostPostMediaItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  mentionedUserIds: (json['mentionedUserIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  mentionedVenueIds: (json['mentionedVenueIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CreateGhostPostRequestToJson(
  CreateGhostPostRequest instance,
) => <String, dynamic>{
  'caption': ?instance.caption,
  'media': ?instance.media?.map((e) => e.toJson()).toList(),
  'mentionedUserIds': ?instance.mentionedUserIds,
  'mentionedVenueIds': ?instance.mentionedVenueIds,
};

GhostPostMediaItem _$GhostPostMediaItemFromJson(Map<String, dynamic> json) =>
    GhostPostMediaItem(
      key: json['key'] as String,
      mediaType: json['mediaType'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GhostPostMediaItemToJson(GhostPostMediaItem instance) =>
    <String, dynamic>{
      'key': instance.key,
      'mediaType': instance.mediaType,
      'sortOrder': instance.sortOrder,
      'aspectRatio': instance.aspectRatio,
    };
