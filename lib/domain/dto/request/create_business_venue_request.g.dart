// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_business_venue_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBusinessVenueRequest _$CreateBusinessVenueRequestFromJson(
  Map<String, dynamic> json,
) => CreateBusinessVenueRequest(
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String?,
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  addressAr: json['addressAr'] as String?,
  addressEn: json['addressEn'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  districtId: (json['districtId'] as num?)?.toInt(),
  phone: json['phone'] as String?,
  website: json['website'] as String?,
  inheritStyle: json['inheritStyle'] as bool? ?? true,
  style: json['style'] as String?,
  onlineOnly: json['onlineOnly'] as bool? ?? false,
  handle: json['handle'] as String?,
);

Map<String, dynamic> _$CreateBusinessVenueRequestToJson(
  CreateBusinessVenueRequest instance,
) => <String, dynamic>{
  'nameAr': instance.nameAr,
  'nameEn': ?instance.nameEn,
  'descriptionAr': ?instance.descriptionAr,
  'descriptionEn': ?instance.descriptionEn,
  'categoryId': ?instance.categoryId,
  'latitude': ?instance.latitude,
  'longitude': ?instance.longitude,
  'addressAr': ?instance.addressAr,
  'addressEn': ?instance.addressEn,
  'cityId': ?instance.cityId,
  'districtId': ?instance.districtId,
  'phone': ?instance.phone,
  'website': ?instance.website,
  'inheritStyle': instance.inheritStyle,
  'style': ?instance.style,
  'onlineOnly': instance.onlineOnly,
  'handle': ?instance.handle,
};
