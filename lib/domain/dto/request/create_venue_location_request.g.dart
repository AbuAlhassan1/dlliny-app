// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_venue_location_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateVenueLocationRequest _$CreateVenueLocationRequestFromJson(
  Map<String, dynamic> json,
) => CreateVenueLocationRequest(
  labelAr: json['labelAr'] as String?,
  labelEn: json['labelEn'] as String?,
  addressAr: json['addressAr'] as String?,
  addressEn: json['addressEn'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  districtId: (json['districtId'] as num?)?.toInt(),
  phone: json['phone'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  isPrimary: json['isPrimary'] as bool?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateVenueLocationRequestToJson(
  CreateVenueLocationRequest instance,
) => <String, dynamic>{
  'labelAr': ?instance.labelAr,
  'labelEn': ?instance.labelEn,
  'addressAr': ?instance.addressAr,
  'addressEn': ?instance.addressEn,
  'cityId': ?instance.cityId,
  'districtId': ?instance.districtId,
  'phone': ?instance.phone,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'isPrimary': ?instance.isPrimary,
  'sortOrder': ?instance.sortOrder,
};
