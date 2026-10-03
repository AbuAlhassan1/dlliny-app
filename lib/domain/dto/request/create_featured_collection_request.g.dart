// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_featured_collection_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateFeaturedCollectionRequest _$CreateFeaturedCollectionRequestFromJson(
  Map<String, dynamic> json,
) => CreateFeaturedCollectionRequest(
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String,
  themeEmoji: json['themeEmoji'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  startsAt: json['startsAt'] as String,
  endsAt: json['endsAt'] as String,
  position: (json['position'] as num?)?.toInt(),
  venues: (json['venues'] as List<dynamic>)
      .map((e) => CollectionVenueItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CreateFeaturedCollectionRequestToJson(
  CreateFeaturedCollectionRequest instance,
) => <String, dynamic>{
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'themeEmoji': ?instance.themeEmoji,
  'cityId': ?instance.cityId,
  'startsAt': instance.startsAt,
  'endsAt': instance.endsAt,
  'position': ?instance.position,
  'venues': instance.venues.map((e) => e.toJson()).toList(),
};

CollectionVenueItem _$CollectionVenueItemFromJson(Map<String, dynamic> json) =>
    CollectionVenueItem(
      venueId: json['venueId'] as String,
      positionInCollection: (json['positionInCollection'] as num).toInt(),
      overrideNoteAr: json['overrideNoteAr'] as String?,
      overrideNoteEn: json['overrideNoteEn'] as String?,
    );

Map<String, dynamic> _$CollectionVenueItemToJson(
  CollectionVenueItem instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'positionInCollection': instance.positionInCollection,
  'overrideNoteAr': ?instance.overrideNoteAr,
  'overrideNoteEn': ?instance.overrideNoteEn,
};
