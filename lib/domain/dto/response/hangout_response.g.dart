// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hangout_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HangoutResponse _$HangoutResponseFromJson(Map<String, dynamic> json) =>
    HangoutResponse(
      id: json['id'] as String,
      organizerId: json['organizerId'] as String,
      organizerUsername: json['organizerUsername'] as String,
      organizerAvatarUrl: json['organizerAvatarUrl'] as String?,
      venueId: json['venueId'] as String,
      venueNameAr: json['venueNameAr'] as String,
      venueNameEn: json['venueNameEn'] as String,
      branch: json['branch'] == null
          ? null
          : HangoutBranch.fromJson(json['branch'] as Map<String, dynamic>),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailMediaType: json['thumbnailMediaType'] as String?,
      description: json['description'] as String?,
      scheduledAt: json['scheduledAt'] as String,
      attendeeCount: (json['attendeeCount'] as num).toInt(),
      likesCount: (json['likesCount'] as num).toInt(),
      commentsCount: (json['commentsCount'] as num).toInt(),
      status: json['status'] as String,
      whatsappLink: json['whatsappLink'] as String?,
      inviteLink: json['inviteLink'] as String?,
      joinPolicy: json['joinPolicy'] as String,
      postVisibility: json['postVisibility'] as String,
      createdAt: json['createdAt'] as String,
      mine: json['mine'] as bool? ?? false,
      likedByMe: json['likedByMe'] as bool? ?? false,
      viewerInvitation: json['viewerInvitation'] == null
          ? null
          : HangoutResponseViewerInvitation.fromJson(
              json['viewerInvitation'] as Map<String, dynamic>,
            ),
      acceptedInvitees:
          (json['acceptedInvitees'] as List<dynamic>?)
              ?.map(
                (e) =>
                    HangoutAttendeeSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      pendingInvitees:
          (json['pendingInvitees'] as List<dynamic>?)
              ?.map(
                (e) =>
                    HangoutAttendeeSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$HangoutResponseToJson(HangoutResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organizerId': instance.organizerId,
      'organizerUsername': instance.organizerUsername,
      'organizerAvatarUrl': instance.organizerAvatarUrl,
      'venueId': instance.venueId,
      'venueNameAr': instance.venueNameAr,
      'venueNameEn': instance.venueNameEn,
      'branch': instance.branch,
      'thumbnailUrl': instance.thumbnailUrl,
      'thumbnailMediaType': instance.thumbnailMediaType,
      'description': instance.description,
      'scheduledAt': instance.scheduledAt,
      'attendeeCount': instance.attendeeCount,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'status': instance.status,
      'whatsappLink': instance.whatsappLink,
      'inviteLink': instance.inviteLink,
      'joinPolicy': instance.joinPolicy,
      'postVisibility': instance.postVisibility,
      'createdAt': instance.createdAt,
      'mine': instance.mine,
      'likedByMe': instance.likedByMe,
      'viewerInvitation': instance.viewerInvitation,
      'acceptedInvitees': instance.acceptedInvitees,
      'pendingInvitees': instance.pendingInvitees,
    };

HangoutBranch _$HangoutBranchFromJson(Map<String, dynamic> json) =>
    HangoutBranch(
      id: json['id'] as String,
      labelAr: json['labelAr'] as String?,
      labelEn: json['labelEn'] as String?,
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$HangoutBranchToJson(HangoutBranch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labelAr': instance.labelAr,
      'labelEn': instance.labelEn,
      'addressAr': instance.addressAr,
      'addressEn': instance.addressEn,
      'isPrimary': instance.isPrimary,
    };

HangoutAttendeeSummary _$HangoutAttendeeSummaryFromJson(
  Map<String, dynamic> json,
) => HangoutAttendeeSummary(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$HangoutAttendeeSummaryToJson(
  HangoutAttendeeSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
};

HangoutResponseViewerInvitation _$HangoutResponseViewerInvitationFromJson(
  Map<String, dynamic> json,
) => HangoutResponseViewerInvitation(
  id: json['id'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$HangoutResponseViewerInvitationToJson(
  HangoutResponseViewerInvitation instance,
) => <String, dynamic>{'id': instance.id, 'status': instance.status};

InvitationResponse _$InvitationResponseFromJson(Map<String, dynamic> json) =>
    InvitationResponse(
      id: json['id'] as String,
      hangoutId: json['hangoutId'] as String,
      venueId: json['venueId'] as String,
      venueNameAr: json['venueNameAr'] as String,
      venueNameEn: json['venueNameEn'] as String,
      hangoutScheduledAt: json['hangoutScheduledAt'] as String,
      invitedById: json['invitedById'] as String,
      invitedByUsername: json['invitedByUsername'] as String,
      status: json['status'] as String,
      message: json['message'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$InvitationResponseToJson(InvitationResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hangoutId': instance.hangoutId,
      'venueId': instance.venueId,
      'venueNameAr': instance.venueNameAr,
      'venueNameEn': instance.venueNameEn,
      'hangoutScheduledAt': instance.hangoutScheduledAt,
      'invitedById': instance.invitedById,
      'invitedByUsername': instance.invitedByUsername,
      'status': instance.status,
      'message': instance.message,
      'createdAt': instance.createdAt,
    };

HangoutCommentAuthor _$HangoutCommentAuthorFromJson(
  Map<String, dynamic> json,
) => HangoutCommentAuthor(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$HangoutCommentAuthorToJson(
  HangoutCommentAuthor instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
};

HangoutCommentResponse _$HangoutCommentResponseFromJson(
  Map<String, dynamic> json,
) => HangoutCommentResponse(
  id: json['id'] as String,
  hangoutId: json['hangoutId'] as String,
  author: HangoutCommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
  body: json['body'] as String,
  mine: json['mine'] as bool,
  createdAt: json['createdAt'] as String,
  parentCommentId: json['parentCommentId'] as String?,
  replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HangoutCommentResponseToJson(
  HangoutCommentResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'hangoutId': instance.hangoutId,
  'author': instance.author,
  'body': instance.body,
  'mine': instance.mine,
  'createdAt': instance.createdAt,
  'parentCommentId': instance.parentCommentId,
  'replyCount': instance.replyCount,
};

HangoutMediaResponse _$HangoutMediaResponseFromJson(
  Map<String, dynamic> json,
) => HangoutMediaResponse(
  id: json['id'] as String,
  url: json['url'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  streamUrl: json['streamUrl'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$HangoutMediaResponseToJson(
  HangoutMediaResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': instance.aspectRatio,
  'thumbnailUrl': instance.thumbnailUrl,
  'streamUrl': instance.streamUrl,
  'createdAt': instance.createdAt,
};

MediaUploadUrlResponse _$MediaUploadUrlResponseFromJson(
  Map<String, dynamic> json,
) => MediaUploadUrlResponse(
  uploadUrl: json['uploadUrl'] as String,
  key: json['key'] as String,
);

Map<String, dynamic> _$MediaUploadUrlResponseToJson(
  MediaUploadUrlResponse instance,
) => <String, dynamic>{'uploadUrl': instance.uploadUrl, 'key': instance.key};

MapHangoutPinResponse _$MapHangoutPinResponseFromJson(
  Map<String, dynamic> json,
) => MapHangoutPinResponse(
  hangoutId: json['hangoutId'] as String,
  scheduledAt: json['scheduledAt'] as String,
  venueId: json['venueId'] as String,
  venueNameAr: json['venueNameAr'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$MapHangoutPinResponseToJson(
  MapHangoutPinResponse instance,
) => <String, dynamic>{
  'hangoutId': instance.hangoutId,
  'scheduledAt': instance.scheduledAt,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
