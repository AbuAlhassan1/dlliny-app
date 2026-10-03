// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'username_availability_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsernameAvailabilityResponse _$UsernameAvailabilityResponseFromJson(
  Map<String, dynamic> json,
) => UsernameAvailabilityResponse(
  username: json['username'] as String,
  available: json['available'] as bool,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$UsernameAvailabilityResponseToJson(
  UsernameAvailabilityResponse instance,
) => <String, dynamic>{
  'username': instance.username,
  'available': instance.available,
  'reason': instance.reason,
};
