import 'package:json_annotation/json_annotation.dart';

part 'google_sign_in_request.g.dart';

@JsonSerializable(includeIfNull: false)
class GoogleSignInRequest {
  final String idToken;
  final String? deviceId;
  final String? platform;
  final String? fcmToken;

  const GoogleSignInRequest({
    required this.idToken,
    this.deviceId,
    this.platform,
    this.fcmToken,
  });

  factory GoogleSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSignInRequestToJson(this);
}
