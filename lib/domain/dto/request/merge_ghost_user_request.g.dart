// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merge_ghost_user_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MergeGhostUserRequest _$MergeGhostUserRequestFromJson(
  Map<String, dynamic> json,
) => MergeGhostUserRequest(
  confirm: json['confirm'] as bool,
  keepUsername: json['keepUsername'] as String?,
  keepDisplayName: json['keepDisplayName'] as String?,
  keepBio: json['keepBio'] as String?,
  keepAvatar: json['keepAvatar'] as String?,
  keepCover: json['keepCover'] as String?,
);

Map<String, dynamic> _$MergeGhostUserRequestToJson(
  MergeGhostUserRequest instance,
) => <String, dynamic>{
  'confirm': instance.confirm,
  'keepUsername': ?instance.keepUsername,
  'keepDisplayName': ?instance.keepDisplayName,
  'keepBio': ?instance.keepBio,
  'keepAvatar': ?instance.keepAvatar,
  'keepCover': ?instance.keepCover,
};
