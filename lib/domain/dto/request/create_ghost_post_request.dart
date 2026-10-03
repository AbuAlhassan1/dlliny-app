import 'package:json_annotation/json_annotation.dart';

part 'create_ghost_post_request.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CreateGhostPostRequest {
  final String? caption;
  final List<GhostPostMediaItem>? media;

  final List<String>? mentionedUserIds;

  final List<String>? mentionedVenueIds;

  const CreateGhostPostRequest({
    this.caption,
    this.media,
    this.mentionedUserIds,
    this.mentionedVenueIds,
  });

  factory CreateGhostPostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGhostPostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateGhostPostRequestToJson(this);
}

@JsonSerializable()
class GhostPostMediaItem {
  final String key;

  final String mediaType;

  final int sortOrder;

  final double? aspectRatio;

  const GhostPostMediaItem({
    required this.key,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
  });

  factory GhostPostMediaItem.fromJson(Map<String, dynamic> json) =>
      _$GhostPostMediaItemFromJson(json);
  Map<String, dynamic> toJson() => _$GhostPostMediaItemToJson(this);
}
