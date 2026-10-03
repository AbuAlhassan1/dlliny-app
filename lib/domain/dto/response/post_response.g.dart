// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorInfo _$AuthorInfoFromJson(Map<String, dynamic> json) => AuthorInfo(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$AuthorInfoToJson(AuthorInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => MediaItem(
  url: json['url'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  streamUrl: json['streamUrl'] as String?,
);

Map<String, dynamic> _$MediaItemToJson(MediaItem instance) => <String, dynamic>{
  'url': instance.url,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': instance.aspectRatio,
  'thumbnailUrl': instance.thumbnailUrl,
  'streamUrl': instance.streamUrl,
};

UserMention _$UserMentionFromJson(Map<String, dynamic> json) => UserMention(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$UserMentionToJson(UserMention instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

VenueMention _$VenueMentionFromJson(Map<String, dynamic> json) => VenueMention(
  id: json['id'] as String,
  nameAr: json['nameAr'] as String?,
  nameEn: json['nameEn'] as String?,
);

Map<String, dynamic> _$VenueMentionToJson(VenueMention instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
    };

VenueAuthorInfo _$VenueAuthorInfoFromJson(Map<String, dynamic> json) =>
    VenueAuthorInfo(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String?,
      nameEn: json['nameEn'] as String?,
      logoUrl: json['logoUrl'] as String?,
      onlineOnly: json['onlineOnly'] as bool? ?? false,
    );

Map<String, dynamic> _$VenueAuthorInfoToJson(VenueAuthorInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'logoUrl': instance.logoUrl,
      'onlineOnly': instance.onlineOnly,
    };

PostResponse _$PostResponseFromJson(Map<String, dynamic> json) => PostResponse(
  id: json['id'] as String,
  author: json['author'] == null
      ? null
      : AuthorInfo.fromJson(json['author'] as Map<String, dynamic>),
  venueAuthor: json['venueAuthor'] == null
      ? null
      : VenueAuthorInfo.fromJson(json['venueAuthor'] as Map<String, dynamic>),
  caption: json['caption'] as String?,
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  likedByMe: json['likedByMe'] as bool,
  mine: json['mine'] as bool,
  media: (json['media'] as List<dynamic>)
      .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  userMentions: (json['userMentions'] as List<dynamic>)
      .map((e) => UserMention.fromJson(e as Map<String, dynamic>))
      .toList(),
  venueMentions: (json['venueMentions'] as List<dynamic>)
      .map((e) => VenueMention.fromJson(e as Map<String, dynamic>))
      .toList(),
  isProduct: json['isProduct'] as bool? ?? false,
  price: (json['price'] as num?)?.toDouble(),
  priceCurrency: json['priceCurrency'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$PostResponseToJson(PostResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author?.toJson(),
      'venueAuthor': instance.venueAuthor?.toJson(),
      'caption': instance.caption,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'likedByMe': instance.likedByMe,
      'mine': instance.mine,
      'media': instance.media.map((e) => e.toJson()).toList(),
      'userMentions': instance.userMentions.map((e) => e.toJson()).toList(),
      'venueMentions': instance.venueMentions.map((e) => e.toJson()).toList(),
      'isProduct': instance.isProduct,
      'price': instance.price,
      'priceCurrency': instance.priceCurrency,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

CommentResponse _$CommentResponseFromJson(Map<String, dynamic> json) =>
    CommentResponse(
      id: json['id'] as String,
      postId: json['postId'] as String,
      author: AuthorInfo.fromJson(json['author'] as Map<String, dynamic>),
      body: json['body'] as String,
      mine: json['mine'] as bool,
      createdAt: json['createdAt'] as String?,
      parentCommentId: json['parentCommentId'] as String?,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CommentResponseToJson(CommentResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'author': instance.author.toJson(),
      'body': instance.body,
      'mine': instance.mine,
      'createdAt': instance.createdAt,
      'parentCommentId': instance.parentCommentId,
      'replyCount': instance.replyCount,
    };
