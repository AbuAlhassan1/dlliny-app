import 'package:json_annotation/json_annotation.dart';

part 'shake_recommendation_response.g.dart';

@JsonSerializable()
class ShakeRecommendationItem {
  final String venueId;
  final String nameAr;
  final String? nameEn;
  final String? handle;
  final double? lat;
  final double? lng;
  final String? logoUrl;
  final String? coverUrl;

  final String? coverStreamUrl;
  final double? avgRating;
  final int? totalRatings;
  final String? categoryCode;

  @JsonKey(defaultValue: <String>[])
  final List<String> matchingTagCodes;
  @JsonKey(defaultValue: <String>[])
  final List<String> matchingTagNamesAr;
  @JsonKey(defaultValue: <String>[])
  final List<String> matchingTagNamesEn;

  final double? matchScore;

  final String? reasonAr;
  final String? reasonEn;

  final int? distanceMeters;

  const ShakeRecommendationItem({
    required this.venueId,
    required this.nameAr,
    this.nameEn,
    this.handle,
    this.lat,
    this.lng,
    this.logoUrl,
    this.coverUrl,
    this.coverStreamUrl,
    this.avgRating,
    this.totalRatings,
    this.categoryCode,
    this.matchingTagCodes = const [],
    this.matchingTagNamesAr = const [],
    this.matchingTagNamesEn = const [],
    this.matchScore,
    this.reasonAr,
    this.reasonEn,
    this.distanceMeters,
  });

  factory ShakeRecommendationItem.fromJson(Map<String, dynamic> json) =>
      _$ShakeRecommendationItemFromJson(json);
  Map<String, dynamic> toJson() => _$ShakeRecommendationItemToJson(this);
}

@JsonSerializable()
class ShakeRecommendationResponse {
  final String mode;

  final String status;
  final List<ShakeRecommendationItem> venues;

  const ShakeRecommendationResponse({
    required this.mode,
    required this.status,
    required this.venues,
  });

  factory ShakeRecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$ShakeRecommendationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ShakeRecommendationResponseToJson(this);
}
