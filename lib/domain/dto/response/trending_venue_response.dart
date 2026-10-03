import 'package:json_annotation/json_annotation.dart';

part 'trending_venue_response.g.dart';

@JsonSerializable()
class TrendingVenueResponse {
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

  final int score;

  const TrendingVenueResponse({
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
    required this.score,
  });

  factory TrendingVenueResponse.fromJson(Map<String, dynamic> json) =>
      _$TrendingVenueResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TrendingVenueResponseToJson(this);
}
