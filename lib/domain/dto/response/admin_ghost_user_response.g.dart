// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_ghost_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminGhostUserResponse _$AdminGhostUserResponseFromJson(
  Map<String, dynamic> json,
) => AdminGhostUserResponse(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  bio: json['bio'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  city: json['city'] as String?,
  district: json['district'] as String?,
  preferredLang: json['preferredLang'] as String?,
  isGhost: json['isGhost'] as bool,
  createdByAdminId: json['createdByAdminId'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$AdminGhostUserResponseToJson(
  AdminGhostUserResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'bio': instance.bio,
  'avatarUrl': instance.avatarUrl,
  'coverUrl': instance.coverUrl,
  'city': instance.city,
  'district': instance.district,
  'preferredLang': instance.preferredLang,
  'isGhost': instance.isGhost,
  'createdByAdminId': instance.createdByAdminId,
  'createdAt': instance.createdAt,
};
