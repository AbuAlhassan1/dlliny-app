// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachGalleryPhotoRequest _$AttachGalleryPhotoRequestFromJson(
  Map<String, dynamic> json,
) => AttachGalleryPhotoRequest(
  key: json['key'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  placeholderHash: json['placeholderHash'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  venueLocationId: json['venueLocationId'] as String?,
);

Map<String, dynamic> _$AttachGalleryPhotoRequestToJson(
  AttachGalleryPhotoRequest instance,
) => <String, dynamic>{
  'key': instance.key,
  'width': instance.width,
  'height': instance.height,
  'placeholderHash': ?instance.placeholderHash,
  'tags': instance.tags,
  'venueLocationId': ?instance.venueLocationId,
};

UpdateGalleryPhotoRequest _$UpdateGalleryPhotoRequestFromJson(
  Map<String, dynamic> json,
) => UpdateGalleryPhotoRequest(
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  venueLocationId: json['venueLocationId'] as String?,
);

Map<String, dynamic> _$UpdateGalleryPhotoRequestToJson(
  UpdateGalleryPhotoRequest instance,
) => <String, dynamic>{
  'tags': ?instance.tags,
  'venueLocationId': ?instance.venueLocationId,
};

ReorderGalleryRequest _$ReorderGalleryRequestFromJson(
  Map<String, dynamic> json,
) => ReorderGalleryRequest(
  photoIds: (json['photoIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ReorderGalleryRequestToJson(
  ReorderGalleryRequest instance,
) => <String, dynamic>{'photoIds': instance.photoIds};
