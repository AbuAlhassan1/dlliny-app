import 'package:json_annotation/json_annotation.dart';

part 'review_response.g.dart';

@JsonSerializable()
class ReviewResponse {
  final String id;
  final String venueId;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final int ratingOverall;
  final int? ratingAtmosphere;
  final int? ratingService;
  final int? ratingValue;
  final String? body;
  final String? businessReply;
  final String? repliedAt;
  final String createdAt;

  const ReviewResponse({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.ratingOverall,
    this.ratingAtmosphere,
    this.ratingService,
    this.ratingValue,
    this.body,
    this.businessReply,
    this.repliedAt,
    required this.createdAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewResponseToJson(this);
}
