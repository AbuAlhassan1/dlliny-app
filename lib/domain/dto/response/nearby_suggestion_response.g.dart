// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_suggestion_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NearbySuggestionResponse _$NearbySuggestionResponseFromJson(
  Map<String, dynamic> json,
) => NearbySuggestionResponse(
  userId: json['userId'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  verified: json['verified'] as bool? ?? false,
  mutualFollowers: (json['mutualFollowers'] as num?)?.toInt() ?? 0,
  sharedVenueNameAr: json['sharedVenueNameAr'] as String?,
  sharedVenueNameEn: json['sharedVenueNameEn'] as String?,
);

Map<String, dynamic> _$NearbySuggestionResponseToJson(
  NearbySuggestionResponse instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'verified': instance.verified,
  'mutualFollowers': instance.mutualFollowers,
  'sharedVenueNameAr': instance.sharedVenueNameAr,
  'sharedVenueNameEn': instance.sharedVenueNameEn,
};
