import 'package:json_annotation/json_annotation.dart';

part 'featured_collection_response.g.dart';

@JsonSerializable(explicitToJson: true)
class FeaturedCollectionResponse {
  final String id;
  final String titleAr;
  final String titleEn;

  final String? themeEmoji;

  final int? cityId;

  final String startsAt;
  final String endsAt;

  final int position;

  final String createdByAdminId;
  final String createdAt;
  final String updatedAt;

  @JsonKey(defaultValue: <CollectionVenue>[])
  final List<CollectionVenue> venues;

  const FeaturedCollectionResponse({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.themeEmoji,
    this.cityId,
    required this.startsAt,
    required this.endsAt,
    required this.position,
    required this.createdByAdminId,
    required this.createdAt,
    required this.updatedAt,
    this.venues = const [],
  });

  factory FeaturedCollectionResponse.fromJson(Map<String, dynamic> json) =>
      _$FeaturedCollectionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FeaturedCollectionResponseToJson(this);
}

@JsonSerializable()
class CollectionVenue {
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
  final int positionInCollection;
  final String? overrideNoteAr;
  final String? overrideNoteEn;

  const CollectionVenue({
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
    required this.positionInCollection,
    this.overrideNoteAr,
    this.overrideNoteEn,
  });

  factory CollectionVenue.fromJson(Map<String, dynamic> json) =>
      _$CollectionVenueFromJson(json);
  Map<String, dynamic> toJson() => _$CollectionVenueToJson(this);
}
