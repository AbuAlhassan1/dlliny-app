import 'package:json_annotation/json_annotation.dart';

part 'admin_hangout_response.g.dart';

@JsonSerializable()
class AdminHangoutResponse {
  final String id;

  final String organizerId;
  final String organizerUsername;

  final String venueId;
  final String venueNameAr;
  final String venueNameEn;

  final String? venueLocationId;

  final String? description;

  final String scheduledAt;

  final String status;

  final String joinPolicy;

  final String postVisibility;

  final String? whatsappLink;

  final int likesCount;
  final int commentsCount;

  final bool hidden;

  final bool active;

  final String createdAt;

  const AdminHangoutResponse({
    required this.id,
    required this.organizerId,
    required this.organizerUsername,
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    this.venueLocationId,
    this.description,
    required this.scheduledAt,
    required this.status,
    required this.joinPolicy,
    required this.postVisibility,
    this.whatsappLink,
    required this.likesCount,
    required this.commentsCount,
    required this.hidden,
    required this.active,
    required this.createdAt,
  });

  factory AdminHangoutResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminHangoutResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AdminHangoutResponseToJson(this);
}
