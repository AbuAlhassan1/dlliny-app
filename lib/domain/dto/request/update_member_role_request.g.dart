// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_member_role_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMemberRoleRequest _$UpdateMemberRoleRequestFromJson(
  Map<String, dynamic> json,
) => UpdateMemberRoleRequest(
  role: $enumDecode(_$ChatMemberRoleEnumMap, json['role']),
);

Map<String, dynamic> _$UpdateMemberRoleRequestToJson(
  UpdateMemberRoleRequest instance,
) => <String, dynamic>{'role': _$ChatMemberRoleEnumMap[instance.role]!};

const _$ChatMemberRoleEnumMap = {
  ChatMemberRole.member: 'MEMBER',
  ChatMemberRole.admin: 'ADMIN',
};
