import 'package:json_annotation/json_annotation.dart';

part 'post_response.g.dart';

@JsonSerializable()
class AuthorInfo {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const AuthorInfo({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory AuthorInfo.fromJson(Map<String, dynamic> json) =>
      _$AuthorInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorInfoToJson(this);
}

@JsonSerializable()
class MediaItem {
  final String url;
  final String mediaType;
  final int sortOrder;

  final double? aspectRatio;

  final String? thumbnailUrl;

  final String? streamUrl;

  const MediaItem({
    required this.url,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
    this.thumbnailUrl,
    this.streamUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  Map<String, dynamic> toJson() => _$MediaItemToJson(this);
}

@JsonSerializable()
class UserMention {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const UserMention({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory UserMention.fromJson(Map<String, dynamic> json) =>
      _$UserMentionFromJson(json);

  Map<String, dynamic> toJson() => _$UserMentionToJson(this);
}

@JsonSerializable()
class VenueMention {
  final String id;
  final String? nameAr;
  final String? nameEn;

  const VenueMention({
    required this.id,
    this.nameAr,
    this.nameEn,
  });

  factory VenueMention.fromJson(Map<String, dynamic> json) =>
      _$VenueMentionFromJson(json);

  Map<String, dynamic> toJson() => _$VenueMentionToJson(this);
}

@JsonSerializable()
class VenueAuthorInfo {
  final String id;
  final String? nameAr;
  final String? nameEn;

  final String? logoUrl;

  @JsonKey(defaultValue: false)
  final bool onlineOnly;

  const VenueAuthorInfo({
    required this.id,
    this.nameAr,
    this.nameEn,
    this.logoUrl,
    this.onlineOnly = false,
  });

  factory VenueAuthorInfo.fromJson(Map<String, dynamic> json) =>
      _$VenueAuthorInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueAuthorInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PostResponse {
  final String id;

  final AuthorInfo? author;

  final VenueAuthorInfo? venueAuthor;

  final String? caption;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final bool mine;
  final List<MediaItem> media;
  final List<UserMention> userMentions;
  final List<VenueMention> venueMentions;

  @JsonKey(defaultValue: false)
  final bool isProduct;

  final double? price;

  final String? priceCurrency;

  final String createdAt;
  final String? updatedAt;

  const PostResponse({
    required this.id,
    this.author,
    this.venueAuthor,
    this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
    required this.mine,
    required this.media,
    required this.userMentions,
    required this.venueMentions,
    this.isProduct = false,
    this.price,
    this.priceCurrency,
    required this.createdAt,
    this.updatedAt,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) =>
      _$PostResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PostResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CommentResponse {
  final String id;
  final String postId;
  final AuthorInfo author;
  final String body;
  final bool mine;

  final String? createdAt;
  final String? parentCommentId;
  final int replyCount;

  const CommentResponse({
    required this.id,
    required this.postId,
    required this.author,
    required this.body,
    required this.mine,
    this.createdAt,
    this.parentCommentId,
    this.replyCount = 0,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) =>
      _$CommentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommentResponseToJson(this);
}
