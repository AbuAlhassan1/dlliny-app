import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'business_gallery_response.g.dart';

@JsonSerializable(explicitToJson: true)
class BusinessGalleryResponse {
  @JsonKey(defaultValue: <GalleryPhotoDto>[])
  final List<GalleryPhotoDto> photos;

  final int maxPhotos;

  final int remaining;

  @JsonKey(defaultValue: <String>[])
  final List<String> privacyHintTags;

  const BusinessGalleryResponse({
    this.photos = const [],
    required this.maxPhotos,
    required this.remaining,
    this.privacyHintTags = const [],
  });

  factory BusinessGalleryResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessGalleryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessGalleryResponseToJson(this);
}

@JsonSerializable()
class GalleryUploadUrlResponse {
  final String uploadUrl;

  final String key;

  final int expiresInSeconds;

  final int maxBytes;

  const GalleryUploadUrlResponse({
    required this.uploadUrl,
    required this.key,
    required this.expiresInSeconds,
    required this.maxBytes,
  });

  factory GalleryUploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$GalleryUploadUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryUploadUrlResponseToJson(this);
}
