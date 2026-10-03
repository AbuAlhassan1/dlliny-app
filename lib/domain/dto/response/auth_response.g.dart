// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  isNewUser: json['isNewUser'] as bool,
  user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
  businesses:
      (json['businesses'] as List<dynamic>?)
          ?.map(
            (e) => BusinessAccountSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
  venueRoles:
      (json['venueRoles'] as List<dynamic>?)
          ?.map((e) => VenueRoleSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  subscriptions:
      (json['subscriptions'] as List<dynamic>?)
          ?.map(
            (e) => AuthSubscriptionSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'isNewUser': instance.isNewUser,
      'user': instance.user.toJson(),
      'businesses': instance.businesses.map((e) => e.toJson()).toList(),
      'venueRoles': instance.venueRoles.map((e) => e.toJson()).toList(),
      'subscriptions': instance.subscriptions.map((e) => e.toJson()).toList(),
    };

AuthSubscriptionSummary _$AuthSubscriptionSummaryFromJson(
  Map<String, dynamic> json,
) => AuthSubscriptionSummary(
  id: json['id'] as String,
  tierId: json['tierId'] as String,
  tierName: json['tierName'] as String,
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  expiresAt: json['expiresAt'] as String,
  primary: json['primary'] as bool? ?? false,
);

Map<String, dynamic> _$AuthSubscriptionSummaryToJson(
  AuthSubscriptionSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'tierId': instance.tierId,
  'tierName': instance.tierName,
  'permissions': instance.permissions,
  'expiresAt': instance.expiresAt,
  'primary': instance.primary,
};

BusinessAccountSummary _$BusinessAccountSummaryFromJson(
  Map<String, dynamic> json,
) => BusinessAccountSummary(
  id: json['id'] as String,
  ownerName: json['ownerName'] as String,
  companyName: json['companyName'] as String?,
  verified: json['verified'] as bool,
);

Map<String, dynamic> _$BusinessAccountSummaryToJson(
  BusinessAccountSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'ownerName': instance.ownerName,
  'companyName': instance.companyName,
  'verified': instance.verified,
};

VenueRoleSummary _$VenueRoleSummaryFromJson(Map<String, dynamic> json) =>
    VenueRoleSummary(
      venueId: json['venueId'] as String,
      venueNameEn: json['venueNameEn'] as String,
      venueNameAr: json['venueNameAr'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$VenueRoleSummaryToJson(VenueRoleSummary instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'venueNameEn': instance.venueNameEn,
      'venueNameAr': instance.venueNameAr,
      'role': instance.role,
    };

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as String,
  phoneNumber: json['phoneNumber'] as String?,
  username: json['username'] as String?,
  displayName: json['displayName'] as String?,
  bio: json['bio'] as String?,
  gender: json['gender'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  city: json['city'] as String?,
  district: json['district'] as String?,
  verified: json['verified'] as bool,
  followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
  followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
  postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
  hangoutsCount: (json['hangoutsCount'] as num?)?.toInt() ?? 0,
  isFollowing: json['isFollowing'] as bool? ?? false,
  followStatus: $enumDecodeNullable(
    _$FollowStatusEnumMap,
    json['followStatus'],
  ),
  isPrivate: json['isPrivate'] as bool? ?? false,
  totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  level: (json['level'] as num?)?.toInt() ?? 1,
  currentLevelThreshold: (json['currentLevelThreshold'] as num?)?.toInt() ?? 0,
  nextLevelThreshold: (json['nextLevelThreshold'] as num?)?.toInt(),
  pointsToNextLevel: (json['pointsToNextLevel'] as num?)?.toInt() ?? 0,
  isMaxLevel: json['isMaxLevel'] as bool? ?? false,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'phoneNumber': instance.phoneNumber,
  'username': instance.username,
  'displayName': instance.displayName,
  'bio': instance.bio,
  'gender': instance.gender,
  'avatarUrl': instance.avatarUrl,
  'coverUrl': instance.coverUrl,
  'city': instance.city,
  'district': instance.district,
  'verified': instance.verified,
  'followersCount': instance.followersCount,
  'followingCount': instance.followingCount,
  'postsCount': instance.postsCount,
  'hangoutsCount': instance.hangoutsCount,
  'isFollowing': instance.isFollowing,
  'followStatus': _$FollowStatusEnumMap[instance.followStatus],
  'isPrivate': instance.isPrivate,
  'totalPoints': instance.totalPoints,
  'level': instance.level,
  'currentLevelThreshold': instance.currentLevelThreshold,
  'nextLevelThreshold': instance.nextLevelThreshold,
  'pointsToNextLevel': instance.pointsToNextLevel,
  'isMaxLevel': instance.isMaxLevel,
};

const _$FollowStatusEnumMap = {
  FollowStatus.pending: 'PENDING',
  FollowStatus.accepted: 'ACCEPTED',
};

UploadUrlResponse _$UploadUrlResponseFromJson(Map<String, dynamic> json) =>
    UploadUrlResponse(
      uploadUrl: json['uploadUrl'] as String,
      key: json['key'] as String,
    );

Map<String, dynamic> _$UploadUrlResponseToJson(UploadUrlResponse instance) =>
    <String, dynamic>{'uploadUrl': instance.uploadUrl, 'key': instance.key};
