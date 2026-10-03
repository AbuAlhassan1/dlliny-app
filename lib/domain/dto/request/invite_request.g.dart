// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteRequest _$InviteRequestFromJson(Map<String, dynamic> json) =>
    InviteRequest(
      userIds: (json['userIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$InviteRequestToJson(InviteRequest instance) =>
    <String, dynamic>{'userIds': instance.userIds, 'message': instance.message};
