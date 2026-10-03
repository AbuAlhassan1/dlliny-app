// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_recommendations_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklyRecommendationsResponse _$WeeklyRecommendationsResponseFromJson(
  Map<String, dynamic> json,
) => WeeklyRecommendationsResponse(
  weekStartsAt: json['weekStartsAt'] as String,
  isFallback: json['isFallback'] as bool,
  items: (json['items'] as List<dynamic>)
      .map((e) => WeeklyRecommendationItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WeeklyRecommendationsResponseToJson(
  WeeklyRecommendationsResponse instance,
) => <String, dynamic>{
  'weekStartsAt': instance.weekStartsAt,
  'isFallback': instance.isFallback,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

WeeklyRecommendationItem _$WeeklyRecommendationItemFromJson(
  Map<String, dynamic> json,
) => WeeklyRecommendationItem(
  venueId: json['venueId'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String?,
  handle: json['handle'] as String?,
  logoUrl: json['logoUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  coverStreamUrl: json['coverStreamUrl'] as String?,
  avgRating: (json['avgRating'] as num?)?.toDouble(),
  totalRatings: (json['totalRatings'] as num?)?.toInt(),
  categoryCode: json['categoryCode'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  position: (json['position'] as num).toInt(),
  score: (json['score'] as num).toDouble(),
  fallback: json['fallback'] as bool,
);

Map<String, dynamic> _$WeeklyRecommendationItemToJson(
  WeeklyRecommendationItem instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'handle': instance.handle,
  'logoUrl': instance.logoUrl,
  'coverUrl': instance.coverUrl,
  'coverStreamUrl': instance.coverStreamUrl,
  'avgRating': instance.avgRating,
  'totalRatings': instance.totalRatings,
  'categoryCode': instance.categoryCode,
  'lat': instance.lat,
  'lng': instance.lng,
  'position': instance.position,
  'score': instance.score,
  'fallback': instance.fallback,
};
