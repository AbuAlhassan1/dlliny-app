import 'package:json_annotation/json_annotation.dart';

part 'username_availability_response.g.dart';

@JsonSerializable(explicitToJson: false)
class UsernameAvailabilityResponse {
  final String username;
  final bool available;
  final String? reason;

  const UsernameAvailabilityResponse({
    required this.username,
    required this.available,
    this.reason,
  });

  factory UsernameAvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      _$UsernameAvailabilityResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UsernameAvailabilityResponseToJson(this);
}
