// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_featured_collection_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateFeaturedCollectionRequest _$UpdateFeaturedCollectionRequestFromJson(
  Map<String, dynamic> json,
) => UpdateFeaturedCollectionRequest(
  titleAr: json['titleAr'] as String?,
  titleEn: json['titleEn'] as String?,
  themeEmoji: json['themeEmoji'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  startsAt: json['startsAt'] as String?,
  endsAt: json['endsAt'] as String?,
  position: (json['position'] as num?)?.toInt(),
  venues: (json['venues'] as List<dynamic>?)
      ?.map((e) => CollectionVenueItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UpdateFeaturedCollectionRequestToJson(
  UpdateFeaturedCollectionRequest instance,
) => <String, dynamic>{
  'titleAr': ?instance.titleAr,
  'titleEn': ?instance.titleEn,
  'themeEmoji': ?instance.themeEmoji,
  'cityId': ?instance.cityId,
  'startsAt': ?instance.startsAt,
  'endsAt': ?instance.endsAt,
  'position': ?instance.position,
  'venues': ?instance.venues?.map((e) => e.toJson()).toList(),
};
