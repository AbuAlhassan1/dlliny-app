import 'package:json_annotation/json_annotation.dart';

part 'create_featured_collection_request.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CreateFeaturedCollectionRequest {
  final String titleAr;
  final String titleEn;
  final String? themeEmoji;
  final int? cityId;
  final String startsAt;
  final String endsAt;
  final int? position;
  final List<CollectionVenueItem> venues;

  const CreateFeaturedCollectionRequest({
    required this.titleAr,
    required this.titleEn,
    this.themeEmoji,
    this.cityId,
    required this.startsAt,
    required this.endsAt,
    this.position,
    required this.venues,
  });

  factory CreateFeaturedCollectionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateFeaturedCollectionRequestFromJson(json);
  Map<String, dynamic> toJson() =>
      _$CreateFeaturedCollectionRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CollectionVenueItem {
  final String venueId;
  final int positionInCollection;
  final String? overrideNoteAr;
  final String? overrideNoteEn;

  const CollectionVenueItem({
    required this.venueId,
    required this.positionInCollection,
    this.overrideNoteAr,
    this.overrideNoteEn,
  });

  factory CollectionVenueItem.fromJson(Map<String, dynamic> json) =>
      _$CollectionVenueItemFromJson(json);
  Map<String, dynamic> toJson() => _$CollectionVenueItemToJson(this);
}
