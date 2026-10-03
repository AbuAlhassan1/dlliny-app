import 'package:json_annotation/json_annotation.dart';

import 'follow_action_response.dart';

part 'auth_response.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final UserDto user;

  @JsonKey(defaultValue: [])
  final List<BusinessAccountSummary> businesses;

  @JsonKey(defaultValue: [])
  final List<VenueRoleSummary> venueRoles;

  @JsonKey(defaultValue: [])
  final List<AuthSubscriptionSummary> subscriptions;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
    required this.user,
    this.businesses = const [],
    this.venueRoles = const [],
    this.subscriptions = const [],
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class AuthSubscriptionSummary {
  final String id;
  final String tierId;
  final String tierName;

  @JsonKey(defaultValue: <String>[])
  final List<String> permissions;

  final String expiresAt;

  @JsonKey(defaultValue: false)
  final bool primary;

  const AuthSubscriptionSummary({
    required this.id,
    required this.tierId,
    required this.tierName,
    this.permissions = const [],
    required this.expiresAt,
    this.primary = false,
  });

  factory AuthSubscriptionSummary.fromJson(Map<String, dynamic> json) =>
      _$AuthSubscriptionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AuthSubscriptionSummaryToJson(this);
}

@JsonSerializable()
class BusinessAccountSummary {
  final String id;
  final String ownerName;
  final String? companyName;
  final bool verified;

  const BusinessAccountSummary({
    required this.id,
    required this.ownerName,
    this.companyName,
    required this.verified,
  });

  factory BusinessAccountSummary.fromJson(Map<String, dynamic> json) =>
      _$BusinessAccountSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessAccountSummaryToJson(this);
}

@JsonSerializable()
class VenueRoleSummary {
  final String venueId;
  final String venueNameEn;
  final String venueNameAr;
  final String role;

  const VenueRoleSummary({
    required this.venueId,
    required this.venueNameEn,
    required this.venueNameAr,
    required this.role,
  });

  factory VenueRoleSummary.fromJson(Map<String, dynamic> json) =>
      _$VenueRoleSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$VenueRoleSummaryToJson(this);
}

@JsonSerializable()
class UserDto {
  final String id;
  final String? phoneNumber;
  final String? username;
  final String? displayName;
  final String? bio;
  final String? gender;
  final String? avatarUrl;
  final String? coverUrl;
  final String? city;
  final String? district;
  final bool verified;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int hangoutsCount;

  @JsonKey(defaultValue: false)
  final bool isFollowing;

  final FollowStatus? followStatus;

  @JsonKey(defaultValue: false)
  final bool isPrivate;

  @JsonKey(defaultValue: 0)
  final int totalPoints;

  @JsonKey(defaultValue: 1)
  final int level;

  @JsonKey(defaultValue: 0)
  final int currentLevelThreshold;

  final int? nextLevelThreshold;

  @JsonKey(defaultValue: 0)
  final int pointsToNextLevel;

  @JsonKey(defaultValue: false)
  final bool isMaxLevel;

  const UserDto({
    required this.id,
    this.phoneNumber,
    this.username,
    this.displayName,
    this.bio,
    this.gender,
    this.avatarUrl,
    this.coverUrl,
    this.city,
    this.district,
    required this.verified,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.hangoutsCount = 0,
    this.isFollowing = false,
    this.followStatus,
    this.isPrivate = false,
    this.totalPoints = 0,
    this.level = 1,
    this.currentLevelThreshold = 0,
    this.nextLevelThreshold,
    this.pointsToNextLevel = 0,
    this.isMaxLevel = false,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

@JsonSerializable()
class UploadUrlResponse {
  final String uploadUrl;
  final String key;

  const UploadUrlResponse({required this.uploadUrl, required this.key});

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadUrlResponseToJson(this);
}
