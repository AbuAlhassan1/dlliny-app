import 'package:json_annotation/json_annotation.dart';

part 'served_ad_response.g.dart';

@JsonSerializable()
class ServedAdItem {
  final String adId;

  final String placement;

  final String? venueId;
  final String? venueNameAr;
  final String? venueNameEn;
  final String? venueLogoUrl;

  final String? sourceType;
  final String? sourcePostId;
  final String? sourceHangoutId;
  final String? mediaUrl;

  final String? mediaType;

  final String? mediaStreamUrl;

  final String? caption;

  final String? sourceCaption;

  final String? ctaText;

  final String? ctaUrl;

  const ServedAdItem({
    required this.adId,
    required this.placement,
    this.venueId,
    this.venueNameAr,
    this.venueNameEn,
    this.venueLogoUrl,
    this.sourceType,
    this.sourcePostId,
    this.sourceHangoutId,
    this.mediaUrl,
    this.mediaType,
    this.mediaStreamUrl,
    this.caption,
    this.sourceCaption,
    this.ctaText,
    this.ctaUrl,
  });

  factory ServedAdItem.fromJson(Map<String, dynamic> json) =>
      _$ServedAdItemFromJson(json);
  Map<String, dynamic> toJson() => _$ServedAdItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ServedAdResponse {
  final String placement;
  final List<ServedAdItem> ads;

  const ServedAdResponse({
    required this.placement,
    required this.ads,
  });

  factory ServedAdResponse.fromJson(Map<String, dynamic> json) =>
      _$ServedAdResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ServedAdResponseToJson(this);
}
