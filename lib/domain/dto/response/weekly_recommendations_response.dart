import 'package:json_annotation/json_annotation.dart';

part 'weekly_recommendations_response.g.dart';

@JsonSerializable(explicitToJson: true)
class WeeklyRecommendationsResponse {
  final String weekStartsAt;
  final bool isFallback;
  final List<WeeklyRecommendationItem> items;

  const WeeklyRecommendationsResponse({
    required this.weekStartsAt,
    required this.isFallback,
    required this.items,
  });

  factory WeeklyRecommendationsResponse.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRecommendationsResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$WeeklyRecommendationsResponseToJson(this);
}

@JsonSerializable()
class WeeklyRecommendationItem {
  final String venueId;
  final String nameAr;
  final String? nameEn;
  final String? handle;
  final String? logoUrl;
  final String? coverUrl;

  final String? coverStreamUrl;
  final double? avgRating;
  final int? totalRatings;
  final String? categoryCode;
  final double? lat;
  final double? lng;

  final int position;

  final double score;

  final bool fallback;

  const WeeklyRecommendationItem({
    required this.venueId,
    required this.nameAr,
    this.nameEn,
    this.handle,
    this.logoUrl,
    this.coverUrl,
    this.coverStreamUrl,
    this.avgRating,
    this.totalRatings,
    this.categoryCode,
    this.lat,
    this.lng,
    required this.position,
    required this.score,
    required this.fallback,
  });

  factory WeeklyRecommendationItem.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRecommendationItemFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyRecommendationItemToJson(this);
}
