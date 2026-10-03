// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_hangout_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateHangoutRequest _$CreateHangoutRequestFromJson(
  Map<String, dynamic> json,
) => CreateHangoutRequest(
  venueId: json['venueId'] as String,
  venueLocationId: json['venueLocationId'] as String?,
  description: json['description'] as String?,
  scheduledAt: json['scheduledAt'] as String,
  joinPolicy: json['joinPolicy'] as String,
  postVisibility: json['postVisibility'] as String,
  whatsappLink: json['whatsappLink'] as String?,
  inviteeUserIds: (json['inviteeUserIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  inviteMessage: json['inviteMessage'] as String?,
);

Map<String, dynamic> _$CreateHangoutRequestToJson(
  CreateHangoutRequest instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'venueLocationId': ?instance.venueLocationId,
  'description': ?instance.description,
  'scheduledAt': instance.scheduledAt,
  'joinPolicy': instance.joinPolicy,
  'postVisibility': instance.postVisibility,
  'whatsappLink': ?instance.whatsappLink,
  'inviteeUserIds': ?instance.inviteeUserIds,
  'inviteMessage': ?instance.inviteMessage,
};
