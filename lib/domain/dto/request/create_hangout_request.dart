import 'package:json_annotation/json_annotation.dart';

part 'create_hangout_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateHangoutRequest {
  final String venueId;

  final String? venueLocationId;

  final String? description;
  final String scheduledAt;
  final String joinPolicy;
  final String postVisibility;
  final String? whatsappLink;
  final List<String>? inviteeUserIds;
  final String? inviteMessage;

  const CreateHangoutRequest({
    required this.venueId,
    this.venueLocationId,
    this.description,
    required this.scheduledAt,
    required this.joinPolicy,
    required this.postVisibility,
    this.whatsappLink,
    this.inviteeUserIds,
    this.inviteMessage,
  });

  factory CreateHangoutRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateHangoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateHangoutRequestToJson(this);
}
