import 'package:json_annotation/json_annotation.dart';

import 'create_featured_collection_request.dart';

part 'update_featured_collection_request.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateFeaturedCollectionRequest {
  final String? titleAr;
  final String? titleEn;
  final String? themeEmoji;
  final int? cityId;
  final String? startsAt;
  final String? endsAt;
  final int? position;
  final List<CollectionVenueItem>? venues;

  const UpdateFeaturedCollectionRequest({
    this.titleAr,
    this.titleEn,
    this.themeEmoji,
    this.cityId,
    this.startsAt,
    this.endsAt,
    this.position,
    this.venues,
  });

  factory UpdateFeaturedCollectionRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateFeaturedCollectionRequestFromJson(json);
  Map<String, dynamic> toJson() =>
      _$UpdateFeaturedCollectionRequestToJson(this);
}
