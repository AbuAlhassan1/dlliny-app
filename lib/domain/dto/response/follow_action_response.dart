import 'package:json_annotation/json_annotation.dart';

part 'follow_action_response.g.dart';

enum FollowStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
}

@JsonSerializable()
class FollowActionResponse {
  final FollowStatus status;

  const FollowActionResponse({required this.status});

  factory FollowActionResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowActionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FollowActionResponseToJson(this);
}
