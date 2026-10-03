// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shake_recommendation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShakeRecommendationItem _$ShakeRecommendationItemFromJson(
  Map<String, dynamic> json,
) => ShakeRecommendationItem(
  venueId: json['venueId'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String?,
  handle: json['handle'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  logoUrl: json['logoUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  coverStreamUrl: json['coverStreamUrl'] as String?,
  avgRating: (json['avgRating'] as num?)?.toDouble(),
  totalRatings: (json['totalRatings'] as num?)?.toInt(),
  categoryCode: json['categoryCode'] as String?,
  matchingTagCodes:
      (json['matchingTagCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  matchingTagNamesAr:
      (json['matchingTagNamesAr'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  matchingTagNamesEn:
      (json['matchingTagNamesEn'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  matchScore: (json['matchScore'] as num?)?.toDouble(),
  reasonAr: json['reasonAr'] as String?,
  reasonEn: json['reasonEn'] as String?,
  distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
);

Map<String, dynamic> _$ShakeRecommendationItemToJson(
  ShakeRecommendationItem instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'handle': instance.handle,
  'lat': instance.lat,
  'lng': instance.lng,
  'logoUrl': instance.logoUrl,
  'coverUrl': instance.coverUrl,
  'coverStreamUrl': instance.coverStreamUrl,
  'avgRating': instance.avgRating,
  'totalRatings': instance.totalRatings,
  'categoryCode': instance.categoryCode,
  'matchingTagCodes': instance.matchingTagCodes,
  'matchingTagNamesAr': instance.matchingTagNamesAr,
  'matchingTagNamesEn': instance.matchingTagNamesEn,
  'matchScore': instance.matchScore,
  'reasonAr': instance.reasonAr,
  'reasonEn': instance.reasonEn,
  'distanceMeters': instance.distanceMeters,
};

ShakeRecommendationResponse _$ShakeRecommendationResponseFromJson(
  Map<String, dynamic> json,
) => ShakeRecommendationResponse(
  mode: json['mode'] as String,
  status: json['status'] as String,
  venues: (json['venues'] as List<dynamic>)
      .map((e) => ShakeRecommendationItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ShakeRecommendationResponseToJson(
  ShakeRecommendationResponse instance,
) => <String, dynamic>{
  'mode': instance.mode,
  'status': instance.status,
  'venues': instance.venues,
};
