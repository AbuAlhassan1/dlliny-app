import 'package:json_annotation/json_annotation.dart';

part 'feed_response.g.dart';

@JsonSerializable()
class FeedMediaItem {
  final String type;
  final String url;

  final double? aspectRatio;

  final String? thumbnailUrl;

  final String? streamUrl;

  const FeedMediaItem({
    required this.type,
    required this.url,
    this.aspectRatio,
    this.thumbnailUrl,
    this.streamUrl,
  });

  factory FeedMediaItem.fromJson(Map<String, dynamic> json) =>
      _$FeedMediaItemFromJson(json);

  Map<String, dynamic> toJson() => _$FeedMediaItemToJson(this);
}

@JsonSerializable()
class PostFeedItem {
  @JsonKey(defaultValue: 'POST')
  final String type;
  final String id;

  final String? authorUserId;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;

  final String? authorVenueId;

  final String? authorVenueName;

  final String? authorVenueNameAr;

  final String? authorVenueNameEn;

  final String? authorVenueLogoUrl;

  @JsonKey(defaultValue: false)
  final bool authorVenueOnlineOnly;

  final String? caption;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final List<FeedMediaItem> mediaUrls;

  @JsonKey(defaultValue: false)
  final bool isProduct;

  final double? price;

  final String? priceCurrency;

  final String createdAt;

  const PostFeedItem({
    required this.type,
    required this.id,
    this.authorUserId,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.authorVenueId,
    this.authorVenueName,
    this.authorVenueNameAr,
    this.authorVenueNameEn,
    this.authorVenueLogoUrl,
    this.caption,
    required this.likesCount,
    required this.commentsCount,
    this.likedByMe = false,
    required this.mediaUrls,
    this.isProduct = false,
    this.price,
    this.priceCurrency,
    this.authorVenueOnlineOnly = false,
    required this.createdAt,
  });

  factory PostFeedItem.fromJson(Map<String, dynamic> json) =>
      _$PostFeedItemFromJson(json);

  Map<String, dynamic> toJson() => _$PostFeedItemToJson(this);
}

@JsonSerializable()
class HangoutOrganizerUser {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const HangoutOrganizerUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory HangoutOrganizerUser.fromJson(Map<String, dynamic> json) =>
      _$HangoutOrganizerUserFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutOrganizerUserToJson(this);
}

@JsonSerializable()
class HangoutOrganizerVenue {
  final String id;
  final String? nameAr;
  final String? nameEn;
  final String? district;
  final String? style;

  final String? logoUrl;

  const HangoutOrganizerVenue({
    required this.id,
    this.nameAr,
    this.nameEn,
    this.district,
    this.style,
    this.logoUrl,
  });

  factory HangoutOrganizerVenue.fromJson(Map<String, dynamic> json) =>
      _$HangoutOrganizerVenueFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutOrganizerVenueToJson(this);
}

@JsonSerializable()
class HangoutFeedBranch {
  final String id;
  final String? labelAr;
  final String? labelEn;
  final String? addressAr;
  final String? addressEn;

  @JsonKey(defaultValue: false)
  final bool isPrimary;

  const HangoutFeedBranch({
    required this.id,
    this.labelAr,
    this.labelEn,
    this.addressAr,
    this.addressEn,
    this.isPrimary = false,
  });

  factory HangoutFeedBranch.fromJson(Map<String, dynamic> json) =>
      _$HangoutFeedBranchFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutFeedBranchToJson(this);
}

@JsonSerializable()
class HangoutViewerInvitation {
  final String id;

  final String status;

  const HangoutViewerInvitation({
    required this.id,
    required this.status,
  });

  factory HangoutViewerInvitation.fromJson(Map<String, dynamic> json) =>
      _$HangoutViewerInvitationFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutViewerInvitationToJson(this);
}

@JsonSerializable()
class HangoutAttendee {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const HangoutAttendee({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory HangoutAttendee.fromJson(Map<String, dynamic> json) =>
      _$HangoutAttendeeFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutAttendeeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HangoutFeedItem {
  @JsonKey(defaultValue: 'HANGOUT')
  final String type;
  final String id;

  final String? title;

  final String? description;
  final String scheduledAt;
  final String status;

  final HangoutOrganizerUser? organizerUser;
  final HangoutOrganizerVenue? organizerVenue;

  final HangoutOrganizerVenue? venue;

  final HangoutFeedBranch? branch;

  final List<HangoutAttendee> attendees;

  @JsonKey(defaultValue: <HangoutAttendee>[])
  final List<HangoutAttendee> pendingInvitees;

  @JsonKey(defaultValue: false)
  final bool mine;

  @JsonKey(defaultValue: false)
  final bool likedByMe;

  final int likesCount;
  final int commentsCount;
  final String joinPolicy;
  final String postVisibility;
  final String? inviteLink;
  final List<FeedMediaItem> media;
  final String createdAt;

  final HangoutViewerInvitation? viewerInvitation;

  const HangoutFeedItem({
    required this.type,
    required this.id,
    this.title,
    this.description,
    required this.scheduledAt,
    required this.status,
    this.organizerUser,
    this.organizerVenue,
    this.venue,
    this.branch,
    required this.attendees,
    this.pendingInvitees = const [],
    this.mine = false,
    this.likedByMe = false,
    required this.likesCount,
    required this.commentsCount,
    required this.joinPolicy,
    required this.postVisibility,
    this.inviteLink,
    required this.media,
    required this.createdAt,
    this.viewerInvitation,
  });

  factory HangoutFeedItem.fromJson(Map<String, dynamic> json) =>
      _$HangoutFeedItemFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutFeedItemToJson(this);
}

@JsonSerializable()
class UpcomingHangoutItem {
  final String id;
  final String scheduledAt;

  final String? organizerUserId;
  final String? organizerUsername;
  final String? organizerAvatarUrl;

  final String? organizerVenueId;
  final String? organizerVenueName;

  final String? venueNameAr;
  final String? venueNameEn;
  final String? venueDistrict;

  final String invitationStatus;

  const UpcomingHangoutItem({
    required this.id,
    required this.scheduledAt,
    this.organizerUserId,
    this.organizerUsername,
    this.organizerAvatarUrl,
    this.organizerVenueId,
    this.organizerVenueName,
    this.venueNameAr,
    this.venueNameEn,
    this.venueDistrict,
    required this.invitationStatus,
  });

  factory UpcomingHangoutItem.fromJson(Map<String, dynamic> json) =>
      _$UpcomingHangoutItemFromJson(json);

  Map<String, dynamic> toJson() => _$UpcomingHangoutItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FollowingFeedResponse {
  final List<UpcomingHangoutItem> urgencyStrip;
  final PagedFeedResponse feed;

  const FollowingFeedResponse({
    required this.urgencyStrip,
    required this.feed,
  });

  factory FollowingFeedResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowingFeedResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FollowingFeedResponseToJson(this);
}

@JsonSerializable()
class PagedFeedResponse {
  final List<Map<String, dynamic>> items;
  final String? nextCursor;
  final bool hasMore;

  const PagedFeedResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory PagedFeedResponse.fromJson(Map<String, dynamic> json) =>
      _$PagedFeedResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PagedFeedResponseToJson(this);

  List<Object> get parsedItems => items.map((item) {
        final type = item['type'] as String?;
        if (type == 'POST') return PostFeedItem.fromJson(item);
        if (type == 'HANGOUT') return HangoutFeedItem.fromJson(item);
        if (item.containsKey('scheduledAt')) {
          return HangoutFeedItem.fromJson(item);
        }
        return PostFeedItem.fromJson(item);
      }).toList();
}

class PagedHangoutFeedResponse {
  final List<HangoutFeedItem> items;
  final String? nextCursor;
  final bool hasMore;

  const PagedHangoutFeedResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory PagedHangoutFeedResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return PagedHangoutFeedResponse(
      items: rawItems
          .map((e) => HangoutFeedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'nextCursor': nextCursor,
        'hasMore': hasMore,
      };
}
