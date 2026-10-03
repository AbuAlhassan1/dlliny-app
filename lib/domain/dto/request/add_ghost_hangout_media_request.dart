import 'package:json_annotation/json_annotation.dart';

part 'add_ghost_hangout_media_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AddGhostHangoutMediaRequest {
  final String key;
  final String mediaType;
  final int sortOrder;
  final double? aspectRatio;

  const AddGhostHangoutMediaRequest({
    required this.key,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
  });

  factory AddGhostHangoutMediaRequest.fromJson(Map<String, dynamic> json) =>
      _$AddGhostHangoutMediaRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddGhostHangoutMediaRequestToJson(this);
}
