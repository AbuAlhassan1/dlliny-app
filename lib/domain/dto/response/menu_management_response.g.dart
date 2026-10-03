// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_management_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItemResponse _$MenuItemResponseFromJson(Map<String, dynamic> json) =>
    MenuItemResponse(
      id: json['id'] as String,
      sectionId: json['sectionId'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      available: json['available'] as bool,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$MenuItemResponseToJson(MenuItemResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sectionId': instance.sectionId,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'descriptionAr': instance.descriptionAr,
      'descriptionEn': instance.descriptionEn,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
      'available': instance.available,
      'sortOrder': instance.sortOrder,
    };

MenuSectionResponse _$MenuSectionResponseFromJson(Map<String, dynamic> json) =>
    MenuSectionResponse(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      active: json['active'] as bool,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => MenuItemResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MenuSectionResponseToJson(
  MenuSectionResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'sortOrder': instance.sortOrder,
  'active': instance.active,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

MenuItemImageUploadResponse _$MenuItemImageUploadResponseFromJson(
  Map<String, dynamic> json,
) => MenuItemImageUploadResponse(
  uploadUrl: json['uploadUrl'] as String,
  key: json['key'] as String,
);

Map<String, dynamic> _$MenuItemImageUploadResponseToJson(
  MenuItemImageUploadResponse instance,
) => <String, dynamic>{'uploadUrl': instance.uploadUrl, 'key': instance.key};
