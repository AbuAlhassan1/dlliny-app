// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_venue_service_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddVenueServiceRequest _$AddVenueServiceRequestFromJson(
  Map<String, dynamic> json,
) => AddVenueServiceRequest(
  serviceTypeId: (json['serviceTypeId'] as num).toInt(),
  price: (json['price'] as num?)?.toDouble(),
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$AddVenueServiceRequestToJson(
  AddVenueServiceRequest instance,
) => <String, dynamic>{
  'serviceTypeId': instance.serviceTypeId,
  'price': ?instance.price,
  'imageUrl': ?instance.imageUrl,
};
