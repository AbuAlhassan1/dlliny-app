// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_post_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPostResponse _$AdminPostResponseFromJson(Map<String, dynamic> json) =>
    AdminPostResponse(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      caption: json['caption'] as String?,
      likesCount: (json['likesCount'] as num).toInt(),
      commentsCount: (json['commentsCount'] as num).toInt(),
      hidden: json['hidden'] as bool,
      active: json['active'] as bool,
      media:
          (json['media'] as List<dynamic>?)
              ?.map(
                (e) => AdminPostMediaItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$AdminPostResponseToJson(AdminPostResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'username': instance.username,
      'caption': instance.caption,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'hidden': instance.hidden,
      'active': instance.active,
      'media': instance.media,
      'createdAt': instance.createdAt,
    };

AdminPostMediaItem _$AdminPostMediaItemFromJson(Map<String, dynamic> json) =>
    AdminPostMediaItem(
      url: json['url'] as String,
      mediaType: json['mediaType'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$AdminPostMediaItemToJson(AdminPostMediaItem instance) =>
    <String, dynamic>{
      'url': instance.url,
      'mediaType': instance.mediaType,
      'sortOrder': instance.sortOrder,
    };
