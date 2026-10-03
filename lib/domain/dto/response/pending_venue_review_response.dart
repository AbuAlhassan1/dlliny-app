import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_venue_review_response.g.dart';

@JsonSerializable()
class PendingVenueReviewResponse {
  final String hangoutId;
  final String scheduledAt;
  final String? hangoutDescription;
  final String attendedAs;

  final String venueId;
  final String venueNameAr;
  final String venueNameEn;
  final String? venueLogoUrl;

  @JsonKey(defaultValue: <HangoutAttendee>[])
  final List<HangoutAttendee> attendees;

  const PendingVenueReviewResponse({
    required this.hangoutId,
    required this.scheduledAt,
    this.hangoutDescription,
    required this.attendedAs,
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    this.venueLogoUrl,
    this.attendees = const [],
  });

  factory PendingVenueReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$PendingVenueReviewResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PendingVenueReviewResponseToJson(this);
}
