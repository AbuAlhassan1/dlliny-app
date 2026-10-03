// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_content_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VenueServiceTypeDto _$VenueServiceTypeDtoFromJson(Map<String, dynamic> json) =>
    VenueServiceTypeDto(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      category: json['category'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$VenueServiceTypeDtoToJson(
  VenueServiceTypeDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'category': instance.category,
  'sortOrder': instance.sortOrder,
};

VenueServiceItemDto _$VenueServiceItemDtoFromJson(Map<String, dynamic> json) =>
    VenueServiceItemDto(
      id: json['id'] as String,
      serviceTypeId: (json['serviceTypeId'] as num).toInt(),
      code: json['code'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      category: json['category'] as String,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$VenueServiceItemDtoToJson(
  VenueServiceItemDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'serviceTypeId': instance.serviceTypeId,
  'code': instance.code,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'category': instance.category,
  'price': instance.price,
  'imageUrl': instance.imageUrl,
};

VenueAnnouncementDto _$VenueAnnouncementDtoFromJson(
  Map<String, dynamic> json,
) => VenueAnnouncementDto(
  id: json['id'] as String,
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String?,
  bodyAr: json['bodyAr'] as String,
  bodyEn: json['bodyEn'] as String?,
  pinned: json['pinned'] as bool,
  publishedAt: json['publishedAt'] as String,
  expiresAt: json['expiresAt'] as String?,
);

Map<String, dynamic> _$VenueAnnouncementDtoToJson(
  VenueAnnouncementDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'bodyAr': instance.bodyAr,
  'bodyEn': instance.bodyEn,
  'pinned': instance.pinned,
  'publishedAt': instance.publishedAt,
  'expiresAt': instance.expiresAt,
};

MenuItemDto _$MenuItemDtoFromJson(Map<String, dynamic> json) => MenuItemDto(
  id: json['id'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String?,
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  imageUrl: json['imageUrl'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

Map<String, dynamic> _$MenuItemDtoToJson(MenuItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'descriptionAr': instance.descriptionAr,
      'descriptionEn': instance.descriptionEn,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
      'sortOrder': instance.sortOrder,
    };

MenuSectionDto _$MenuSectionDtoFromJson(Map<String, dynamic> json) =>
    MenuSectionDto(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => MenuItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MenuSectionDtoToJson(MenuSectionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'sortOrder': instance.sortOrder,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
