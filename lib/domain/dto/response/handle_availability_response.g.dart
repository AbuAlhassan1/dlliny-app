// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handle_availability_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HandleAvailabilityResponse _$HandleAvailabilityResponseFromJson(
  Map<String, dynamic> json,
) => HandleAvailabilityResponse(
  handle: json['handle'] as String,
  available: json['available'] as bool,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$HandleAvailabilityResponseToJson(
  HandleAvailabilityResponse instance,
) => <String, dynamic>{
  'handle': instance.handle,
  'available': instance.available,
  'reason': instance.reason,
};
