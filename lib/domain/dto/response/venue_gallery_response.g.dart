// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_gallery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VenueGalleryDto _$VenueGalleryDtoFromJson(Map<String, dynamic> json) =>
    VenueGalleryDto(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => GalleryPhotoDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tagCounts:
          (json['tagCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          {},
    );

Map<String, dynamic> _$VenueGalleryDtoToJson(VenueGalleryDto instance) =>
    <String, dynamic>{
      'totalCount': instance.totalCount,
      'photos': instance.photos.map((e) => e.toJson()).toList(),
      'tagCounts': instance.tagCounts,
    };

GalleryPhotoDto _$GalleryPhotoDtoFromJson(Map<String, dynamic> json) =>
    GalleryPhotoDto(
      id: json['id'] as String,
      url: json['url'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      placeholderHash: json['placeholderHash'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      locationId: json['locationId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
      hidden: json['hidden'] as bool? ?? false,
      hiddenReason: json['hiddenReason'] as String?,
      hiddenAt: json['hiddenAt'] as String?,
      contentType: json['contentType'] as String?,
      byteSize: (json['byteSize'] as num?)?.toInt(),
      uploadedByUserId: json['uploadedByUserId'] as String?,
    );

Map<String, dynamic> _$GalleryPhotoDtoToJson(GalleryPhotoDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'aspectRatio': instance.aspectRatio,
      'placeholderHash': instance.placeholderHash,
      'tags': instance.tags,
      'locationId': instance.locationId,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt,
      'hidden': instance.hidden,
      'hiddenReason': instance.hiddenReason,
      'hiddenAt': instance.hiddenAt,
      'contentType': instance.contentType,
      'byteSize': instance.byteSize,
      'uploadedByUserId': instance.uploadedByUserId,
    };
