import 'package:json_annotation/json_annotation.dart';

part 'apple_sign_in_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AppleSignInRequest {
  final String idToken;
  final String? deviceId;
  final String? platform;
  final String? fcmToken;

  const AppleSignInRequest({
    required this.idToken,
    this.deviceId,
    this.platform,
    this.fcmToken,
  });

  factory AppleSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$AppleSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AppleSignInRequestToJson(this);
}
