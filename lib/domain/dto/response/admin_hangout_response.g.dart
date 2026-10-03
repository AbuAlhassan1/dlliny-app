// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_hangout_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminHangoutResponse _$AdminHangoutResponseFromJson(
  Map<String, dynamic> json,
) => AdminHangoutResponse(
  id: json['id'] as String,
  organizerId: json['organizerId'] as String,
  organizerUsername: json['organizerUsername'] as String,
  venueId: json['venueId'] as String,
  venueNameAr: json['venueNameAr'] as String,
  venueNameEn: json['venueNameEn'] as String,
  venueLocationId: json['venueLocationId'] as String?,
  description: json['description'] as String?,
  scheduledAt: json['scheduledAt'] as String,
  status: json['status'] as String,
  joinPolicy: json['joinPolicy'] as String,
  postVisibility: json['postVisibility'] as String,
  whatsappLink: json['whatsappLink'] as String?,
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  hidden: json['hidden'] as bool,
  active: json['active'] as bool,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$AdminHangoutResponseToJson(
  AdminHangoutResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'organizerId': instance.organizerId,
  'organizerUsername': instance.organizerUsername,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'venueLocationId': instance.venueLocationId,
  'description': instance.description,
  'scheduledAt': instance.scheduledAt,
  'status': instance.status,
  'joinPolicy': instance.joinPolicy,
  'postVisibility': instance.postVisibility,
  'whatsappLink': instance.whatsappLink,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'hidden': instance.hidden,
  'active': instance.active,
  'createdAt': instance.createdAt,
};
