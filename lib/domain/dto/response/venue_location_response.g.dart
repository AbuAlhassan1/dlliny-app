// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_location_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VenueLocationResponse _$VenueLocationResponseFromJson(
  Map<String, dynamic> json,
) => VenueLocationResponse(
  id: json['id'] as String,
  venueId: json['venueId'] as String,
  labelAr: json['labelAr'] as String?,
  labelEn: json['labelEn'] as String?,
  addressAr: json['addressAr'] as String?,
  addressEn: json['addressEn'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  cityNameAr: json['cityNameAr'] as String?,
  districtId: (json['districtId'] as num?)?.toInt(),
  districtNameAr: json['districtNameAr'] as String?,
  districtNameEn: json['districtNameEn'] as String?,
  phone: json['phone'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  isPrimary: json['isPrimary'] as bool,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

Map<String, dynamic> _$VenueLocationResponseToJson(
  VenueLocationResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'venueId': instance.venueId,
  'labelAr': instance.labelAr,
  'labelEn': instance.labelEn,
  'addressAr': instance.addressAr,
  'addressEn': instance.addressEn,
  'cityId': instance.cityId,
  'cityNameAr': instance.cityNameAr,
  'districtId': instance.districtId,
  'districtNameAr': instance.districtNameAr,
  'districtNameEn': instance.districtNameEn,
  'phone': instance.phone,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'isPrimary': instance.isPrimary,
  'sortOrder': instance.sortOrder,
};
