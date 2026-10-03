import 'package:json_annotation/json_annotation.dart';

part 'create_ghost_hangout_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateGhostHangoutRequest {
  final String venueId;

  final String? venueLocationId;

  final String scheduledAt;

  final String? description;

  final String joinPolicy;

  final String postVisibility;

  final String? whatsappLink;

  final List<String>? inviteeUserIds;

  final List<CreateGhostHangoutMediaItem>? media;

  final String? createdAt;

  const CreateGhostHangoutRequest({
    required this.venueId,
    this.venueLocationId,
    required this.scheduledAt,
    this.description,
    required this.joinPolicy,
    required this.postVisibility,
    this.whatsappLink,
    this.inviteeUserIds,
    this.media,
    this.createdAt,
  });

  factory CreateGhostHangoutRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGhostHangoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateGhostHangoutRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CreateGhostHangoutMediaItem {
  final String key;

  final String mediaType;

  final int sortOrder;

  final double? aspectRatio;

  const CreateGhostHangoutMediaItem({
    required this.key,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
  });

  factory CreateGhostHangoutMediaItem.fromJson(Map<String, dynamic> json) =>
      _$CreateGhostHangoutMediaItemFromJson(json);
  Map<String, dynamic> toJson() =>
      _$CreateGhostHangoutMediaItemToJson(this);
}
