import 'package:json_annotation/json_annotation.dart';

part 'ghost_hangout_media_response.g.dart';

@JsonSerializable()
class GhostHangoutMediaResponse {
  final String id;
  final String hangoutId;
  final String url;
  final String mediaType;
  final int sortOrder;
  final double? aspectRatio;
  final String? thumbnailUrl;

  final String? streamUrl;
  final String createdAt;

  const GhostHangoutMediaResponse({
    required this.id,
    required this.hangoutId,
    required this.url,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
    this.thumbnailUrl,
    this.streamUrl,
    required this.createdAt,
  });

  factory GhostHangoutMediaResponse.fromJson(Map<String, dynamic> json) =>
      _$GhostHangoutMediaResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GhostHangoutMediaResponseToJson(this);
}
