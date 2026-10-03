import 'package:json_annotation/json_annotation.dart';

part 'public_event_media_response.g.dart';

@JsonSerializable()
class PublicEventMediaResponse {
  final String id;

  final String mediaType;
  final String url;

  final String? thumbnailUrl;

  final String? streamUrl;

  final double? aspectRatio;

  @JsonKey(defaultValue: 0)
  final int sortOrder;

  final String? createdAt;

  const PublicEventMediaResponse({
    required this.id,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.streamUrl,
    this.aspectRatio,
    this.sortOrder = 0,
    this.createdAt,
  });

  bool get isVideo => mediaType == 'video';

  String? get coverUrl => isVideo ? thumbnailUrl : url;

  factory PublicEventMediaResponse.fromJson(Map<String, dynamic> json) =>
      _$PublicEventMediaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PublicEventMediaResponseToJson(this);
}
