// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_summary_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSummaryResponse _$UserSummaryResponseFromJson(Map<String, dynamic> json) =>
    UserSummaryResponse(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      verified: json['verified'] as bool,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );

Map<String, dynamic> _$UserSummaryResponseToJson(
  UserSummaryResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'verified': instance.verified,
  'isFollowing': instance.isFollowing,
};
