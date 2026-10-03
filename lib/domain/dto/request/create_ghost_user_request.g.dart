// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ghost_user_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGhostUserRequest _$CreateGhostUserRequestFromJson(
  Map<String, dynamic> json,
) => CreateGhostUserRequest(
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  bio: json['bio'] as String?,
  avatarKey: json['avatarKey'] as String?,
  coverKey: json['coverKey'] as String?,
  city: json['city'] as String?,
  district: json['district'] as String?,
  preferredLang: json['preferredLang'] as String?,
);

Map<String, dynamic> _$CreateGhostUserRequestToJson(
  CreateGhostUserRequest instance,
) => <String, dynamic>{
  'username': instance.username,
  'displayName': instance.displayName,
  'bio': ?instance.bio,
  'avatarKey': ?instance.avatarKey,
  'coverKey': ?instance.coverKey,
  'city': ?instance.city,
  'district': ?instance.district,
  'preferredLang': ?instance.preferredLang,
};
