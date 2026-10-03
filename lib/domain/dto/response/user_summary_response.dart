import 'package:json_annotation/json_annotation.dart';

part 'user_summary_response.g.dart';

@JsonSerializable(explicitToJson: true)
class UserSummaryResponse {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool verified;
  @JsonKey(defaultValue: false)
  final bool isFollowing;

  const UserSummaryResponse({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.verified,
    this.isFollowing = false,
  });

  factory UserSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserSummaryResponseToJson(this);
}
