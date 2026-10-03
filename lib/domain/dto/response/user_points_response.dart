import 'package:json_annotation/json_annotation.dart';

part 'user_points_response.g.dart';

@JsonSerializable()
class UserPointsResponse {
  final int totalPoints;
  final int level;
  final int currentLevelThreshold;
  final int? nextLevelThreshold;
  final int pointsToNextLevel;
  final bool isMaxLevel;

  const UserPointsResponse({
    required this.totalPoints,
    required this.level,
    required this.currentLevelThreshold,
    this.nextLevelThreshold,
    required this.pointsToNextLevel,
    required this.isMaxLevel,
  });

  factory UserPointsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserPointsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserPointsResponseToJson(this);
}
