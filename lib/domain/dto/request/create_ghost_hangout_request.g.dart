// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ghost_hangout_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGhostHangoutRequest _$CreateGhostHangoutRequestFromJson(
  Map<String, dynamic> json,
) => CreateGhostHangoutRequest(
  venueId: json['venueId'] as String,
  venueLocationId: json['venueLocationId'] as String?,
  scheduledAt: json['scheduledAt'] as String,
  description: json['description'] as String?,
  joinPolicy: json['joinPolicy'] as String,
  postVisibility: json['postVisibility'] as String,
  whatsappLink: json['whatsappLink'] as String?,
  inviteeUserIds: (json['inviteeUserIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  media: (json['media'] as List<dynamic>?)
      ?.map(
        (e) => CreateGhostHangoutMediaItem.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$CreateGhostHangoutRequestToJson(
  CreateGhostHangoutRequest instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'venueLocationId': ?instance.venueLocationId,
  'scheduledAt': instance.scheduledAt,
  'description': ?instance.description,
  'joinPolicy': instance.joinPolicy,
  'postVisibility': instance.postVisibility,
  'whatsappLink': ?instance.whatsappLink,
  'inviteeUserIds': ?instance.inviteeUserIds,
  'media': ?instance.media,
  'createdAt': ?instance.createdAt,
};

CreateGhostHangoutMediaItem _$CreateGhostHangoutMediaItemFromJson(
  Map<String, dynamic> json,
) => CreateGhostHangoutMediaItem(
  key: json['key'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CreateGhostHangoutMediaItemToJson(
  CreateGhostHangoutMediaItem instance,
) => <String, dynamic>{
  'key': instance.key,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': ?instance.aspectRatio,
};
