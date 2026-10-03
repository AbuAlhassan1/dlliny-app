// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_sign_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppleSignInRequest _$AppleSignInRequestFromJson(Map<String, dynamic> json) =>
    AppleSignInRequest(
      idToken: json['idToken'] as String,
      deviceId: json['deviceId'] as String?,
      platform: json['platform'] as String?,
      fcmToken: json['fcmToken'] as String?,
    );

Map<String, dynamic> _$AppleSignInRequestToJson(AppleSignInRequest instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
      'deviceId': ?instance.deviceId,
      'platform': ?instance.platform,
      'fcmToken': ?instance.fcmToken,
    };
