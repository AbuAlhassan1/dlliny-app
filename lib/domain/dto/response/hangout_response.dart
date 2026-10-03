import 'package:json_annotation/json_annotation.dart';

part 'hangout_response.g.dart';

@JsonSerializable()
class HangoutResponse {
  final String id;
  final String organizerId;
  final String organizerUsername;
  final String? organizerAvatarUrl;
  final String venueId;
  final String venueNameAr;
  final String venueNameEn;

  final HangoutBranch? branch;

  final String? thumbnailUrl;

  final String? thumbnailMediaType;

  final String? description;
  final String scheduledAt;
  final int attendeeCount;
  final int likesCount;
  final int commentsCount;
  final String status;
  final String? whatsappLink;
  final String? inviteLink;
  final String joinPolicy;
  final String postVisibility;
  final String createdAt;

  @JsonKey(defaultValue: false)
  final bool mine;

  @JsonKey(defaultValue: false)
  final bool likedByMe;

  final HangoutResponseViewerInvitation? viewerInvitation;

  @JsonKey(defaultValue: <HangoutAttendeeSummary>[])
  final List<HangoutAttendeeSummary> acceptedInvitees;

  @JsonKey(defaultValue: <HangoutAttendeeSummary>[])
  final List<HangoutAttendeeSummary> pendingInvitees;

  const HangoutResponse({
    required this.id,
    required this.organizerId,
    required this.organizerUsername,
    this.organizerAvatarUrl,
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    this.branch,
    this.thumbnailUrl,
    this.thumbnailMediaType,
    this.description,
    required this.scheduledAt,
    required this.attendeeCount,
    required this.likesCount,
    required this.commentsCount,
    required this.status,
    this.whatsappLink,
    this.inviteLink,
    required this.joinPolicy,
    required this.postVisibility,
    required this.createdAt,
    this.mine = false,
    this.likedByMe = false,
    this.viewerInvitation,
    this.acceptedInvitees = const [],
    this.pendingInvitees = const [],
  });

  factory HangoutResponse.fromJson(Map<String, dynamic> json) =>
      _$HangoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutResponseToJson(this);
}

@JsonSerializable()
class HangoutBranch {
  final String id;
  final String? labelAr;
  final String? labelEn;
  final String? addressAr;
  final String? addressEn;

  @JsonKey(defaultValue: false)
  final bool isPrimary;

  const HangoutBranch({
    required this.id,
    this.labelAr,
    this.labelEn,
    this.addressAr,
    this.addressEn,
    this.isPrimary = false,
  });

  factory HangoutBranch.fromJson(Map<String, dynamic> json) =>
      _$HangoutBranchFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutBranchToJson(this);
}

@JsonSerializable()
class HangoutAttendeeSummary {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const HangoutAttendeeSummary({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory HangoutAttendeeSummary.fromJson(Map<String, dynamic> json) =>
      _$HangoutAttendeeSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutAttendeeSummaryToJson(this);
}

@JsonSerializable()
class HangoutResponseViewerInvitation {
  final String id;

  final String status;

  const HangoutResponseViewerInvitation({
    required this.id,
    required this.status,
  });

  factory HangoutResponseViewerInvitation.fromJson(Map<String, dynamic> json) =>
      _$HangoutResponseViewerInvitationFromJson(json);

  Map<String, dynamic> toJson() =>
      _$HangoutResponseViewerInvitationToJson(this);
}

@JsonSerializable()
class InvitationResponse {
  final String id;
  final String hangoutId;
  final String venueId;
  final String venueNameAr;
  final String venueNameEn;
  final String hangoutScheduledAt;
  final String invitedById;
  final String invitedByUsername;
  final String status;
  final String? message;
  final String createdAt;

  const InvitationResponse({
    required this.id,
    required this.hangoutId,
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    required this.hangoutScheduledAt,
    required this.invitedById,
    required this.invitedByUsername,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory InvitationResponse.fromJson(Map<String, dynamic> json) =>
      _$InvitationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InvitationResponseToJson(this);
}

@JsonSerializable()
class HangoutCommentAuthor {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const HangoutCommentAuthor({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory HangoutCommentAuthor.fromJson(Map<String, dynamic> json) =>
      _$HangoutCommentAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutCommentAuthorToJson(this);
}

@JsonSerializable()
class HangoutCommentResponse {
  final String id;
  final String hangoutId;
  final HangoutCommentAuthor author;
  final String body;
  final bool mine;
  final String createdAt;

  final String? parentCommentId;

  @JsonKey(defaultValue: 0)
  final int replyCount;

  const HangoutCommentResponse({
    required this.id,
    required this.hangoutId,
    required this.author,
    required this.body,
    required this.mine,
    required this.createdAt,
    this.parentCommentId,
    this.replyCount = 0,
  });

  factory HangoutCommentResponse.fromJson(Map<String, dynamic> json) =>
      _$HangoutCommentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutCommentResponseToJson(this);
}

@JsonSerializable()
class HangoutMediaResponse {
  final String id;
  final String url;
  final String mediaType;
  final int sortOrder;

  final double? aspectRatio;

  final String? thumbnailUrl;

  final String? streamUrl;

  final String? createdAt;

  const HangoutMediaResponse({
    required this.id,
    required this.url,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
    this.thumbnailUrl,
    this.streamUrl,
    this.createdAt,
  });

  factory HangoutMediaResponse.fromJson(Map<String, dynamic> json) =>
      _$HangoutMediaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutMediaResponseToJson(this);
}

@JsonSerializable()
class MediaUploadUrlResponse {
  final String uploadUrl;
  final String key;

  const MediaUploadUrlResponse({
    required this.uploadUrl,
    required this.key,
  });

  factory MediaUploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaUploadUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MediaUploadUrlResponseToJson(this);
}

@JsonSerializable()
class MapHangoutPinResponse {
  final String hangoutId;
  final String scheduledAt;
  final String venueId;
  final String venueNameAr;
  final double latitude;
  final double longitude;

  const MapHangoutPinResponse({
    required this.hangoutId,
    required this.scheduledAt,
    required this.venueId,
    required this.venueNameAr,
    required this.latitude,
    required this.longitude,
  });

  factory MapHangoutPinResponse.fromJson(Map<String, dynamic> json) =>
      _$MapHangoutPinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MapHangoutPinResponseToJson(this);
}
