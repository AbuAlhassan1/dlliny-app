import 'package:json_annotation/json_annotation.dart';

part 'attach_event_media_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AttachEventMediaRequest {
  final String mediaType;

  final String key;

  final String? thumbnailKey;

  final double? aspectRatio;

  final int? sortOrder;

  const AttachEventMediaRequest({
    required this.mediaType,
    required this.key,
    this.thumbnailKey,
    this.aspectRatio,
    this.sortOrder,
  });

  factory AttachEventMediaRequest.fromJson(Map<String, dynamic> json) =>
      _$AttachEventMediaRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AttachEventMediaRequestToJson(this);
}
