import 'package:json_annotation/json_annotation.dart';

part 'create_event_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateEventRequest {
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;

  final String startsAt;
  final String? endsAt;

  final String? externalUrl;
  final String? externalUrlLabel;

  final String? venueId;
  final String? venueLocationId;

  final String? hangoutId;

  const CreateEventRequest({
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.startsAt,
    this.endsAt,
    this.externalUrl,
    this.externalUrlLabel,
    this.venueId,
    this.venueLocationId,
    this.hangoutId,
  });

  factory CreateEventRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateEventRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateEventRequestToJson(this);
}
