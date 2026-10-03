// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedMediaItem _$FeedMediaItemFromJson(Map<String, dynamic> json) =>
    FeedMediaItem(
      type: json['type'] as String,
      url: json['url'] as String,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      streamUrl: json['streamUrl'] as String?,
    );

Map<String, dynamic> _$FeedMediaItemToJson(FeedMediaItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'url': instance.url,
      'aspectRatio': instance.aspectRatio,
      'thumbnailUrl': instance.thumbnailUrl,
      'streamUrl': instance.streamUrl,
    };

PostFeedItem _$PostFeedItemFromJson(Map<String, dynamic> json) => PostFeedItem(
  type: json['type'] as String? ?? 'POST',
  id: json['id'] as String,
  authorUserId: json['authorUserId'] as String?,
  authorUsername: json['authorUsername'] as String?,
  authorDisplayName: json['authorDisplayName'] as String?,
  authorAvatarUrl: json['authorAvatarUrl'] as String?,
  authorVenueId: json['authorVenueId'] as String?,
  authorVenueName: json['authorVenueName'] as String?,
  authorVenueNameAr: json['authorVenueNameAr'] as String?,
  authorVenueNameEn: json['authorVenueNameEn'] as String?,
  authorVenueLogoUrl: json['authorVenueLogoUrl'] as String?,
  caption: json['caption'] as String?,
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  likedByMe: json['likedByMe'] as bool? ?? false,
  mediaUrls: (json['mediaUrls'] as List<dynamic>)
      .map((e) => FeedMediaItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  isProduct: json['isProduct'] as bool? ?? false,
  price: (json['price'] as num?)?.toDouble(),
  priceCurrency: json['priceCurrency'] as String?,
  authorVenueOnlineOnly: json['authorVenueOnlineOnly'] as bool? ?? false,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$PostFeedItemToJson(PostFeedItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': instance.id,
      'authorUserId': instance.authorUserId,
      'authorUsername': instance.authorUsername,
      'authorDisplayName': instance.authorDisplayName,
      'authorAvatarUrl': instance.authorAvatarUrl,
      'authorVenueId': instance.authorVenueId,
      'authorVenueName': instance.authorVenueName,
      'authorVenueNameAr': instance.authorVenueNameAr,
      'authorVenueNameEn': instance.authorVenueNameEn,
      'authorVenueLogoUrl': instance.authorVenueLogoUrl,
      'authorVenueOnlineOnly': instance.authorVenueOnlineOnly,
      'caption': instance.caption,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'likedByMe': instance.likedByMe,
      'mediaUrls': instance.mediaUrls,
      'isProduct': instance.isProduct,
      'price': instance.price,
      'priceCurrency': instance.priceCurrency,
      'createdAt': instance.createdAt,
    };

HangoutOrganizerUser _$HangoutOrganizerUserFromJson(
  Map<String, dynamic> json,
) => HangoutOrganizerUser(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$HangoutOrganizerUserToJson(
  HangoutOrganizerUser instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
};

HangoutOrganizerVenue _$HangoutOrganizerVenueFromJson(
  Map<String, dynamic> json,
) => HangoutOrganizerVenue(
  id: json['id'] as String,
  nameAr: json['nameAr'] as String?,
  nameEn: json['nameEn'] as String?,
  district: json['district'] as String?,
  style: json['style'] as String?,
  logoUrl: json['logoUrl'] as String?,
);

Map<String, dynamic> _$HangoutOrganizerVenueToJson(
  HangoutOrganizerVenue instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'district': instance.district,
  'style': instance.style,
  'logoUrl': instance.logoUrl,
};

HangoutFeedBranch _$HangoutFeedBranchFromJson(Map<String, dynamic> json) =>
    HangoutFeedBranch(
      id: json['id'] as String,
      labelAr: json['labelAr'] as String?,
      labelEn: json['labelEn'] as String?,
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$HangoutFeedBranchToJson(HangoutFeedBranch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labelAr': instance.labelAr,
      'labelEn': instance.labelEn,
      'addressAr': instance.addressAr,
      'addressEn': instance.addressEn,
      'isPrimary': instance.isPrimary,
    };

HangoutViewerInvitation _$HangoutViewerInvitationFromJson(
  Map<String, dynamic> json,
) => HangoutViewerInvitation(
  id: json['id'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$HangoutViewerInvitationToJson(
  HangoutViewerInvitation instance,
) => <String, dynamic>{'id': instance.id, 'status': instance.status};

HangoutAttendee _$HangoutAttendeeFromJson(Map<String, dynamic> json) =>
    HangoutAttendee(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$HangoutAttendeeToJson(HangoutAttendee instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

HangoutFeedItem _$HangoutFeedItemFromJson(Map<String, dynamic> json) =>
    HangoutFeedItem(
      type: json['type'] as String? ?? 'HANGOUT',
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      scheduledAt: json['scheduledAt'] as String,
      status: json['status'] as String,
      organizerUser: json['organizerUser'] == null
          ? null
          : HangoutOrganizerUser.fromJson(
              json['organizerUser'] as Map<String, dynamic>,
            ),
      organizerVenue: json['organizerVenue'] == null
          ? null
          : HangoutOrganizerVenue.fromJson(
              json['organizerVenue'] as Map<String, dynamic>,
            ),
      venue: json['venue'] == null
          ? null
          : HangoutOrganizerVenue.fromJson(
              json['venue'] as Map<String, dynamic>,
            ),
      branch: json['branch'] == null
          ? null
          : HangoutFeedBranch.fromJson(json['branch'] as Map<String, dynamic>),
      attendees: (json['attendees'] as List<dynamic>)
          .map((e) => HangoutAttendee.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingInvitees:
          (json['pendingInvitees'] as List<dynamic>?)
              ?.map((e) => HangoutAttendee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mine: json['mine'] as bool? ?? false,
      likedByMe: json['likedByMe'] as bool? ?? false,
      likesCount: (json['likesCount'] as num).toInt(),
      commentsCount: (json['commentsCount'] as num).toInt(),
      joinPolicy: json['joinPolicy'] as String,
      postVisibility: json['postVisibility'] as String,
      inviteLink: json['inviteLink'] as String?,
      media: (json['media'] as List<dynamic>)
          .map((e) => FeedMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String,
      viewerInvitation: json['viewerInvitation'] == null
          ? null
          : HangoutViewerInvitation.fromJson(
              json['viewerInvitation'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$HangoutFeedItemToJson(
  HangoutFeedItem instance,
) => <String, dynamic>{
  'type': instance.type,
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'scheduledAt': instance.scheduledAt,
  'status': instance.status,
  'organizerUser': instance.organizerUser?.toJson(),
  'organizerVenue': instance.organizerVenue?.toJson(),
  'venue': instance.venue?.toJson(),
  'branch': instance.branch?.toJson(),
  'attendees': instance.attendees.map((e) => e.toJson()).toList(),
  'pendingInvitees': instance.pendingInvitees.map((e) => e.toJson()).toList(),
  'mine': instance.mine,
  'likedByMe': instance.likedByMe,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'joinPolicy': instance.joinPolicy,
  'postVisibility': instance.postVisibility,
  'inviteLink': instance.inviteLink,
  'media': instance.media.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt,
  'viewerInvitation': instance.viewerInvitation?.toJson(),
};

UpcomingHangoutItem _$UpcomingHangoutItemFromJson(Map<String, dynamic> json) =>
    UpcomingHangoutItem(
      id: json['id'] as String,
      scheduledAt: json['scheduledAt'] as String,
      organizerUserId: json['organizerUserId'] as String?,
      organizerUsername: json['organizerUsername'] as String?,
      organizerAvatarUrl: json['organizerAvatarUrl'] as String?,
      organizerVenueId: json['organizerVenueId'] as String?,
      organizerVenueName: json['organizerVenueName'] as String?,
      venueNameAr: json['venueNameAr'] as String?,
      venueNameEn: json['venueNameEn'] as String?,
      venueDistrict: json['venueDistrict'] as String?,
      invitationStatus: json['invitationStatus'] as String,
    );

Map<String, dynamic> _$UpcomingHangoutItemToJson(
  UpcomingHangoutItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'scheduledAt': instance.scheduledAt,
  'organizerUserId': instance.organizerUserId,
  'organizerUsername': instance.organizerUsername,
  'organizerAvatarUrl': instance.organizerAvatarUrl,
  'organizerVenueId': instance.organizerVenueId,
  'organizerVenueName': instance.organizerVenueName,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'venueDistrict': instance.venueDistrict,
  'invitationStatus': instance.invitationStatus,
};

FollowingFeedResponse _$FollowingFeedResponseFromJson(
  Map<String, dynamic> json,
) => FollowingFeedResponse(
  urgencyStrip: (json['urgencyStrip'] as List<dynamic>)
      .map((e) => UpcomingHangoutItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  feed: PagedFeedResponse.fromJson(json['feed'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FollowingFeedResponseToJson(
  FollowingFeedResponse instance,
) => <String, dynamic>{
  'urgencyStrip': instance.urgencyStrip.map((e) => e.toJson()).toList(),
  'feed': instance.feed.toJson(),
};

PagedFeedResponse _$PagedFeedResponseFromJson(Map<String, dynamic> json) =>
    PagedFeedResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool,
    );

Map<String, dynamic> _$PagedFeedResponseToJson(PagedFeedResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'hasMore': instance.hasMore,
    };
