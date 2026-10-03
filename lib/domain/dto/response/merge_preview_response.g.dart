// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merge_preview_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MergePreviewResponse _$MergePreviewResponseFromJson(
  Map<String, dynamic> json,
) => MergePreviewResponse(
  ghostUserId: json['ghostUserId'] as String,
  realUserId: json['realUserId'] as String,
  postsToMigrate: (json['postsToMigrate'] as num).toInt(),
  hangoutsToMigrate: (json['hangoutsToMigrate'] as num).toInt(),
  hangoutInvitationsToMigrate: (json['hangoutInvitationsToMigrate'] as num)
      .toInt(),
  hangoutMediaToMigrate: (json['hangoutMediaToMigrate'] as num).toInt(),
  followersToMigrate: (json['followersToMigrate'] as num).toInt(),
  followingsToMigrate: (json['followingsToMigrate'] as num).toInt(),
  username: FieldComparison.fromJson(json['username'] as Map<String, dynamic>),
  displayName: FieldComparison.fromJson(
    json['displayName'] as Map<String, dynamic>,
  ),
  bio: FieldComparison.fromJson(json['bio'] as Map<String, dynamic>),
  avatarUrl: FieldComparison.fromJson(
    json['avatarUrl'] as Map<String, dynamic>,
  ),
  coverUrl: FieldComparison.fromJson(json['coverUrl'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MergePreviewResponseToJson(
  MergePreviewResponse instance,
) => <String, dynamic>{
  'ghostUserId': instance.ghostUserId,
  'realUserId': instance.realUserId,
  'postsToMigrate': instance.postsToMigrate,
  'hangoutsToMigrate': instance.hangoutsToMigrate,
  'hangoutInvitationsToMigrate': instance.hangoutInvitationsToMigrate,
  'hangoutMediaToMigrate': instance.hangoutMediaToMigrate,
  'followersToMigrate': instance.followersToMigrate,
  'followingsToMigrate': instance.followingsToMigrate,
  'username': instance.username.toJson(),
  'displayName': instance.displayName.toJson(),
  'bio': instance.bio.toJson(),
  'avatarUrl': instance.avatarUrl.toJson(),
  'coverUrl': instance.coverUrl.toJson(),
};

FieldComparison _$FieldComparisonFromJson(Map<String, dynamic> json) =>
    FieldComparison(
      ghostValue: json['ghostValue'] as String?,
      realValue: json['realValue'] as String?,
    );

Map<String, dynamic> _$FieldComparisonToJson(FieldComparison instance) =>
    <String, dynamic>{
      'ghostValue': instance.ghostValue,
      'realValue': instance.realValue,
    };
