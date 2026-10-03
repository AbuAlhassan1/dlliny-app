// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompleteProfileRequest _$CompleteProfileRequestFromJson(
  Map<String, dynamic> json,
) => CompleteProfileRequest(
  username: json['username'] as String?,
  displayName: json['displayName'] as String,
  bio: json['bio'] as String?,
  city: json['city'] as String?,
  district: json['district'] as String?,
  gender: json['gender'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  districtId: (json['districtId'] as num?)?.toInt(),
);

Map<String, dynamic> _$CompleteProfileRequestToJson(
  CompleteProfileRequest instance,
) => <String, dynamic>{
  'username': ?instance.username,
  'displayName': instance.displayName,
  'bio': ?instance.bio,
  'city': ?instance.city,
  'gender': ?instance.gender,
  'district': ?instance.district,
  'cityId': ?instance.cityId,
  'districtId': ?instance.districtId,
};
