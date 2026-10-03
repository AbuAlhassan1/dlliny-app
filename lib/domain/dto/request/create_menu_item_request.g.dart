// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_menu_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMenuItemRequest _$CreateMenuItemRequestFromJson(
  Map<String, dynamic> json,
) => CreateMenuItemRequest(
  sectionId: json['sectionId'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String?,
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  imageUrl: json['imageUrl'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

Map<String, dynamic> _$CreateMenuItemRequestToJson(
  CreateMenuItemRequest instance,
) => <String, dynamic>{
  'sectionId': instance.sectionId,
  'nameAr': instance.nameAr,
  'nameEn': ?instance.nameEn,
  'descriptionAr': ?instance.descriptionAr,
  'descriptionEn': ?instance.descriptionEn,
  'price': ?instance.price,
  'imageUrl': ?instance.imageUrl,
  'sortOrder': instance.sortOrder,
};
