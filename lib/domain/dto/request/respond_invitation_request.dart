import 'package:json_annotation/json_annotation.dart';

part 'respond_invitation_request.g.dart';

@JsonSerializable()
class RespondInvitationRequest {
  final String status;

  const RespondInvitationRequest({required this.status});

  factory RespondInvitationRequest.fromJson(Map<String, dynamic> json) =>
      _$RespondInvitationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RespondInvitationRequestToJson(this);
}
