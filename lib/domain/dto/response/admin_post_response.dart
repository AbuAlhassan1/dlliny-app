import 'package:json_annotation/json_annotation.dart';

part 'admin_post_response.g.dart';

@JsonSerializable()
class AdminPostResponse {
  final String id;

  final String? userId;
  final String? username;

  final String? caption;
  final int likesCount;
  final int commentsCount;

  final bool hidden;

  final bool active;

  @JsonKey(defaultValue: <AdminPostMediaItem>[])
  final List<AdminPostMediaItem> media;
  final String createdAt;

  const AdminPostResponse({
    required this.id,
    this.userId,
    this.username,
    this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.hidden,
    required this.active,
    this.media = const [],
    required this.createdAt,
  });

  factory AdminPostResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminPostResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AdminPostResponseToJson(this);
}

@JsonSerializable()
class AdminPostMediaItem {
  final String url;

  final String mediaType;

  final int sortOrder;

  const AdminPostMediaItem({
    required this.url,
    required this.mediaType,
    required this.sortOrder,
  });

  factory AdminPostMediaItem.fromJson(Map<String, dynamic> json) =>
      _$AdminPostMediaItemFromJson(json);
  Map<String, dynamic> toJson() => _$AdminPostMediaItemToJson(this);
}
