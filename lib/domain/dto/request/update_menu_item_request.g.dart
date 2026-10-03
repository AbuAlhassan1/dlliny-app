// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_menu_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMenuItemRequest _$UpdateMenuItemRequestFromJson(
  Map<String, dynamic> json,
) => UpdateMenuItemRequest(
  sectionId: json['sectionId'] as String?,
  nameAr: json['nameAr'] as String?,
  nameEn: json['nameEn'] as String?,
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  imageUrl: json['imageUrl'] as String?,
  available: json['available'] as bool?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$UpdateMenuItemRequestToJson(
  UpdateMenuItemRequest instance,
) => <String, dynamic>{
  'sectionId': ?instance.sectionId,
  'nameAr': ?instance.nameAr,
  'nameEn': ?instance.nameEn,
  'descriptionAr': ?instance.descriptionAr,
  'descriptionEn': ?instance.descriptionEn,
  'price': ?instance.price,
  'imageUrl': ?instance.imageUrl,
  'available': ?instance.available,
  'sortOrder': ?instance.sortOrder,
};
