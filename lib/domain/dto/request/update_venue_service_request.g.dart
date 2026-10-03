// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_venue_service_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateVenueServiceRequest _$UpdateVenueServiceRequestFromJson(
  Map<String, dynamic> json,
) => UpdateVenueServiceRequest(
  price: (json['price'] as num?)?.toDouble(),
  imageUrl: json['imageUrl'] as String?,
  active: json['active'] as bool?,
);

Map<String, dynamic> _$UpdateVenueServiceRequestToJson(
  UpdateVenueServiceRequest instance,
) => <String, dynamic>{
  'price': ?instance.price,
  'imageUrl': ?instance.imageUrl,
  'active': ?instance.active,
};
