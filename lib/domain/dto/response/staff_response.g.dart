// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignableVenueRole _$AssignableVenueRoleFromJson(Map<String, dynamic> json) =>
    AssignableVenueRole(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$AssignableVenueRoleToJson(
  AssignableVenueRole instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
};

BusinessRoleSummary _$BusinessRoleSummaryFromJson(Map<String, dynamic> json) =>
    BusinessRoleSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BusinessRoleSummaryToJson(
  BusinessRoleSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
};

VenueStaffResponse _$VenueStaffResponseFromJson(Map<String, dynamic> json) =>
    VenueStaffResponse(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      roleId: json['roleId'] as String,
      roleName: json['roleName'] as String,
      grantedAt: DateTime.parse(json['grantedAt'] as String),
    );

Map<String, dynamic> _$VenueStaffResponseToJson(VenueStaffResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'roleId': instance.roleId,
      'roleName': instance.roleName,
      'grantedAt': instance.grantedAt.toIso8601String(),
    };

BusinessStaffResponse _$BusinessStaffResponseFromJson(
  Map<String, dynamic> json,
) => BusinessStaffResponse(
  id: json['id'] as String,
  userId: json['userId'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  roleId: json['roleId'] as String,
  roleName: json['roleName'] as String,
  grantedAt: DateTime.parse(json['grantedAt'] as String),
);

Map<String, dynamic> _$BusinessStaffResponseToJson(
  BusinessStaffResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'roleId': instance.roleId,
  'roleName': instance.roleName,
  'grantedAt': instance.grantedAt.toIso8601String(),
};
