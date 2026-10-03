import 'package:json_annotation/json_annotation.dart';

part 'gallery_requests.g.dart';

const String kClearVenueLocationId = '00000000-0000-0000-0000-000000000000';

@JsonSerializable(includeIfNull: false)
class AttachGalleryPhotoRequest {
  final String key;

  final int width;
  final int height;

  final String? placeholderHash;

  final List<String> tags;

  final String? venueLocationId;

  const AttachGalleryPhotoRequest({
    required this.key,
    required this.width,
    required this.height,
    this.placeholderHash,
    this.tags = const [],
    this.venueLocationId,
  });

  factory AttachGalleryPhotoRequest.fromJson(Map<String, dynamic> json) =>
      _$AttachGalleryPhotoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AttachGalleryPhotoRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class UpdateGalleryPhotoRequest {
  final List<String>? tags;
  final String? venueLocationId;

  const UpdateGalleryPhotoRequest({this.tags, this.venueLocationId});

  factory UpdateGalleryPhotoRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateGalleryPhotoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateGalleryPhotoRequestToJson(this);
}

@JsonSerializable()
class ReorderGalleryRequest {
  final List<String> photoIds;

  const ReorderGalleryRequest({required this.photoIds});

  factory ReorderGalleryRequest.fromJson(Map<String, dynamic> json) =>
      _$ReorderGalleryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReorderGalleryRequestToJson(this);
}
