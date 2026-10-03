// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_sign_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoogleSignInRequest _$GoogleSignInRequestFromJson(Map<String, dynamic> json) =>
    GoogleSignInRequest(
      idToken: json['idToken'] as String,
      deviceId: json['deviceId'] as String?,
      platform: json['platform'] as String?,
      fcmToken: json['fcmToken'] as String?,
    );

Map<String, dynamic> _$GoogleSignInRequestToJson(
  GoogleSignInRequest instance,
) => <String, dynamic>{
  'idToken': instance.idToken,
  'deviceId': ?instance.deviceId,
  'platform': ?instance.platform,
  'fcmToken': ?instance.fcmToken,
};
