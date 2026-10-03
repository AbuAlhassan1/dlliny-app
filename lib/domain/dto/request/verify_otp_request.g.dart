// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    VerifyOtpRequest(
      phoneNumber: json['phoneNumber'] as String,
      otp: json['otp'] as String,
      deviceId: json['deviceId'] as String?,
      platform: json['platform'] as String?,
      fcmToken: json['fcmToken'] as String?,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(VerifyOtpRequest instance) =>
    <String, dynamic>{
      'phoneNumber': instance.phoneNumber,
      'otp': instance.otp,
      'deviceId': instance.deviceId,
      'platform': instance.platform,
      'fcmToken': instance.fcmToken,
    };
