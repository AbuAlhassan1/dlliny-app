import 'package:json_annotation/json_annotation.dart';

part 'create_review_request.g.dart';

@JsonSerializable()
class CreateReviewRequest {
  final String venueId;
  final String? hangoutId;
  final int ratingOverall;
  final int? ratingAtmosphere;
  final int? ratingService;
  final int? ratingValue;
  final String? body;

  const CreateReviewRequest({
    required this.venueId,
    this.hangoutId,
    required this.ratingOverall,
    this.ratingAtmosphere,
    this.ratingService,
    this.ratingValue,
    this.body,
  });

  factory CreateReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReviewRequestToJson(this);
}
