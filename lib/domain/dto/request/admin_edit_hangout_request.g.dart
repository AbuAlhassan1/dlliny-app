// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_edit_hangout_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminEditHangoutRequest _$AdminEditHangoutRequestFromJson(
  Map<String, dynamic> json,
) => AdminEditHangoutRequest(
  venueId: json['venueId'] as String?,
  venueLocationId: json['venueLocationId'] as String?,
  description: json['description'] as String?,
  scheduledAt: json['scheduledAt'] as String?,
  joinPolicy: json['joinPolicy'] as String?,
  postVisibility: json['postVisibility'] as String?,
  status: json['status'] as String?,
  whatsappLink: json['whatsappLink'] as String?,
);

Map<String, dynamic> _$AdminEditHangoutRequestToJson(
  AdminEditHangoutRequest instance,
) => <String, dynamic>{
  'venueId': ?instance.venueId,
  'venueLocationId': ?instance.venueLocationId,
  'description': ?instance.description,
  'scheduledAt': ?instance.scheduledAt,
  'joinPolicy': ?instance.joinPolicy,
  'postVisibility': ?instance.postVisibility,
  'status': ?instance.status,
  'whatsappLink': ?instance.whatsappLink,
};
