import 'package:json_annotation/json_annotation.dart';

part 'ghost_post_media_response.g.dart';

@JsonSerializable()
class GhostPostMediaResponse {
  final String id;
  final String postId;
  final String url;
  final String mediaType;
  final int sortOrder;
  final double? aspectRatio;

  final String? thumbnailUrl;

  final String? streamUrl;

  final String createdAt;

  const GhostPostMediaResponse({
    required this.id,
    required this.postId,
    required this.url,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
    this.thumbnailUrl,
    this.streamUrl,
    required this.createdAt,
  });

  factory GhostPostMediaResponse.fromJson(Map<String, dynamic> json) =>
      _$GhostPostMediaResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GhostPostMediaResponseToJson(this);
}
