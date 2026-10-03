// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_action_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowActionResponse _$FollowActionResponseFromJson(
  Map<String, dynamic> json,
) => FollowActionResponse(
  status: $enumDecode(_$FollowStatusEnumMap, json['status']),
);

Map<String, dynamic> _$FollowActionResponseToJson(
  FollowActionResponse instance,
) => <String, dynamic>{'status': _$FollowStatusEnumMap[instance.status]!};

const _$FollowStatusEnumMap = {
  FollowStatus.pending: 'PENDING',
  FollowStatus.accepted: 'ACCEPTED',
};
