import 'package:json_annotation/json_annotation.dart';

part 'create_post_request.g.dart';

@JsonSerializable()
class PostMediaItem {
  final String key;
  final String mediaType;
  final int sortOrder;

  final double? aspectRatio;

  const PostMediaItem({
    required this.key,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
  });

  factory PostMediaItem.fromJson(Map<String, dynamic> json) =>
      _$PostMediaItemFromJson(json);

  Map<String, dynamic> toJson() => _$PostMediaItemToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CreatePostRequest {
  final String? caption;
  final List<PostMediaItem>? media;
  final List<String>? mentionedUserIds;
  final List<String>? mentionedVenueIds;

  final bool? isProduct;

  final double? price;

  const CreatePostRequest({
    this.caption,
    this.media,
    this.mentionedUserIds,
    this.mentionedVenueIds,
    this.isProduct,
    this.price,
  });

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}
