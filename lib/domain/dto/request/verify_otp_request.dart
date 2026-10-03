import 'package:json_annotation/json_annotation.dart';

part 'verify_otp_request.g.dart';

@JsonSerializable()
class VerifyOtpRequest {
  final String phoneNumber;
  final String otp;
  final String? deviceId;
  final String? platform;
  final String? fcmToken;

  const VerifyOtpRequest({
    required this.phoneNumber,
    required this.otp,
    this.deviceId,
    this.platform,
    this.fcmToken,
  });

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpRequestToJson(this);
}
