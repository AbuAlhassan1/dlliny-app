// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proximity_ping_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProximityPingRequest _$ProximityPingRequestFromJson(
  Map<String, dynamic> json,
) => ProximityPingRequest(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$ProximityPingRequestToJson(
  ProximityPingRequest instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
