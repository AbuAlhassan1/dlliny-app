import 'package:json_annotation/json_annotation.dart';

part 'update_event_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateEventRequest {
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;

  final String? startsAt;
  final String? endsAt;

  final String? externalUrl;
  final String? externalUrlLabel;

  final String? venueId;
  final String? venueLocationId;
  final String? hangoutId;

  final bool? active;

  const UpdateEventRequest({
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.startsAt,
    this.endsAt,
    this.externalUrl,
    this.externalUrlLabel,
    this.venueId,
    this.venueLocationId,
    this.hangoutId,
    this.active,
  });

  factory UpdateEventRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEventRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateEventRequestToJson(this);
}
