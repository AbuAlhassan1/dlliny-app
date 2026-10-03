import 'package:json_annotation/json_annotation.dart';

part 'venue_gallery_response.g.dart';

@JsonSerializable(explicitToJson: true)
class VenueGalleryDto {
  @JsonKey(defaultValue: 0)
  final int totalCount;

  @JsonKey(defaultValue: <GalleryPhotoDto>[])
  final List<GalleryPhotoDto> photos;

  @JsonKey(defaultValue: <String, int>{})
  final Map<String, int> tagCounts;

  const VenueGalleryDto({
    this.totalCount = 0,
    this.photos = const [],
    this.tagCounts = const {},
  });

  factory VenueGalleryDto.fromJson(Map<String, dynamic> json) =>
      _$VenueGalleryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueGalleryDtoToJson(this);
}

@JsonSerializable()
class GalleryPhotoDto {
  final String id;

  final String url;

  final int width;
  final int height;

  final double? aspectRatio;

  final String? placeholderHash;

  @JsonKey(defaultValue: <String>[])
  final List<String> tags;

  final String? locationId;

  @JsonKey(defaultValue: 0)
  final int sortOrder;

  final String? createdAt;

  @JsonKey(defaultValue: false)
  final bool hidden;
  final String? hiddenReason;
  final String? hiddenAt;
  final String? contentType;
  final int? byteSize;
  final String? uploadedByUserId;

  const GalleryPhotoDto({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    this.aspectRatio,
    this.placeholderHash,
    this.tags = const [],
    this.locationId,
    this.sortOrder = 0,
    this.createdAt,
    this.hidden = false,
    this.hiddenReason,
    this.hiddenAt,
    this.contentType,
    this.byteSize,
    this.uploadedByUserId,
  });

  double get ratio =>
      aspectRatio ?? (width > 0 && height > 0 ? width / height : 1);

  factory GalleryPhotoDto.fromJson(Map<String, dynamic> json) =>
      _$GalleryPhotoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPhotoDtoToJson(this);
}
