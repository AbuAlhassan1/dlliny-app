// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostMediaItem _$PostMediaItemFromJson(Map<String, dynamic> json) =>
    PostMediaItem(
      key: json['key'] as String,
      mediaType: json['mediaType'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PostMediaItemToJson(PostMediaItem instance) =>
    <String, dynamic>{
      'key': instance.key,
      'mediaType': instance.mediaType,
      'sortOrder': instance.sortOrder,
      'aspectRatio': instance.aspectRatio,
    };

CreatePostRequest _$CreatePostRequestFromJson(Map<String, dynamic> json) =>
    CreatePostRequest(
      caption: json['caption'] as String?,
      media: (json['media'] as List<dynamic>?)
          ?.map((e) => PostMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      mentionedUserIds: (json['mentionedUserIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mentionedVenueIds: (json['mentionedVenueIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isProduct: json['isProduct'] as bool?,
      price: (json['price'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CreatePostRequestToJson(CreatePostRequest instance) =>
    <String, dynamic>{
      'caption': ?instance.caption,
      'media': ?instance.media?.map((e) => e.toJson()).toList(),
      'mentionedUserIds': ?instance.mentionedUserIds,
      'mentionedVenueIds': ?instance.mentionedVenueIds,
      'isProduct': ?instance.isProduct,
      'price': ?instance.price,
    };
