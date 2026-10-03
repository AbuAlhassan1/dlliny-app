// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  displayName: json['displayName'] as String?,
  bio: json['bio'] as String?,
  city: json['city'] as String?,
  district: json['district'] as String?,
  preferredLang: json['preferredLang'] as String?,
  isPrivate: json['isPrivate'] as bool?,
  cityId: (json['cityId'] as num?)?.toInt(),
  districtId: (json['districtId'] as num?)?.toInt(),
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'displayName': ?instance.displayName,
  'bio': ?instance.bio,
  'city': ?instance.city,
  'district': ?instance.district,
  'preferredLang': ?instance.preferredLang,
  'isPrivate': ?instance.isPrivate,
  'cityId': ?instance.cityId,
  'districtId': ?instance.districtId,
};
