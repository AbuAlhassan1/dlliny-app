import 'package:json_annotation/json_annotation.dart';

part 'register_fcm_token_request.g.dart';

@JsonSerializable()
class RegisterFcmTokenRequest {
  final String fcmToken;

  const RegisterFcmTokenRequest({required this.fcmToken});

  factory RegisterFcmTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterFcmTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterFcmTokenRequestToJson(this);
}
