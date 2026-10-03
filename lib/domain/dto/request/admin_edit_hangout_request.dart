import 'package:json_annotation/json_annotation.dart';

part 'admin_edit_hangout_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AdminEditHangoutRequest {
  final String? venueId;

  final String? venueLocationId;

  final String? description;

  final String? scheduledAt;

  final String? joinPolicy;

  final String? postVisibility;

  final String? status;

  final String? whatsappLink;

  const AdminEditHangoutRequest({
    this.venueId,
    this.venueLocationId,
    this.description,
    this.scheduledAt,
    this.joinPolicy,
    this.postVisibility,
    this.status,
    this.whatsappLink,
  });

  factory AdminEditHangoutRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminEditHangoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AdminEditHangoutRequestToJson(this);
}
