import 'package:json_annotation/json_annotation.dart';

import 'challenge_enums.dart';

part 'user_challenge_progress_response.g.dart';

@JsonSerializable()
class UserChallengeProgressResponse {
  final ChallengeProgressStatus status;
  final int totalPointsEarned;
  final int completedObjectiveCount;
  final int totalObjectiveCount;
  final String? completedAt;
  final String joinedAt;

  const UserChallengeProgressResponse({
    required this.status,
    required this.totalPointsEarned,
    required this.completedObjectiveCount,
    required this.totalObjectiveCount,
    this.completedAt,
    required this.joinedAt,
  });

  factory UserChallengeProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$UserChallengeProgressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserChallengeProgressResponseToJson(this);
}
