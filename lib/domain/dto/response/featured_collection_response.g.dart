// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_collection_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeaturedCollectionResponse _$FeaturedCollectionResponseFromJson(
  Map<String, dynamic> json,
) => FeaturedCollectionResponse(
  id: json['id'] as String,
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String,
  themeEmoji: json['themeEmoji'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  startsAt: json['startsAt'] as String,
  endsAt: json['endsAt'] as String,
  position: (json['position'] as num).toInt(),
  createdByAdminId: json['createdByAdminId'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  venues:
      (json['venues'] as List<dynamic>?)
          ?.map((e) => CollectionVenue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$FeaturedCollectionResponseToJson(
  FeaturedCollectionResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'themeEmoji': instance.themeEmoji,
  'cityId': instance.cityId,
  'startsAt': instance.startsAt,
  'endsAt': instance.endsAt,
  'position': instance.position,
  'createdByAdminId': instance.createdByAdminId,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'venues': instance.venues.map((e) => e.toJson()).toList(),
};

CollectionVenue _$CollectionVenueFromJson(Map<String, dynamic> json) =>
    CollectionVenue(
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
      positionInCollection: (json['positionInCollection'] as num).toInt(),
      overrideNoteAr: json['overrideNoteAr'] as String?,
      overrideNoteEn: json['overrideNoteEn'] as String?,
    );

Map<String, dynamic> _$CollectionVenueToJson(CollectionVenue instance) =>
    <String, dynamic>{
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
      'positionInCollection': instance.positionInCollection,
      'overrideNoteAr': instance.overrideNoteAr,
      'overrideNoteEn': instance.overrideNoteEn,
    };
