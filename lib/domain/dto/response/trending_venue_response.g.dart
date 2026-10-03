// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trending_venue_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrendingVenueResponse _$TrendingVenueResponseFromJson(
  Map<String, dynamic> json,
) => TrendingVenueResponse(
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
  score: (json['score'] as num).toInt(),
);

Map<String, dynamic> _$TrendingVenueResponseToJson(
  TrendingVenueResponse instance,
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
  'score': instance.score,
};
