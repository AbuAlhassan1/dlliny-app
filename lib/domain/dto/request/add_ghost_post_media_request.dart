import 'package:json_annotation/json_annotation.dart';

part 'add_ghost_post_media_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AddGhostPostMediaRequest {
  final String key;

  final String mediaType;

  final int sortOrder;

  final double? aspectRatio;

  const AddGhostPostMediaRequest({
    required this.key,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
  });

  factory AddGhostPostMediaRequest.fromJson(Map<String, dynamic> json) =>
      _$AddGhostPostMediaRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddGhostPostMediaRequestToJson(this);
}
