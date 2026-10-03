import 'package:json_annotation/json_annotation.dart';

import 'challenge_enums.dart';

part 'objective_with_progress_response.g.dart';

@JsonSerializable()
class ObjectiveWithProgressResponse {
  final String id;
  final ChallengeObjectiveType type;

  final Map<String, dynamic> config;

  final int points;
  final int sortOrder;
  final String? titleAr;
  final String? titleEn;

  final int? progressValue;
  final int target;
  final bool completed;
  final String? completedAt;

  const ObjectiveWithProgressResponse({
    required this.id,
    required this.type,
    required this.config,
    required this.points,
    required this.sortOrder,
    this.titleAr,
    this.titleEn,
    this.progressValue,
    required this.target,
    required this.completed,
    this.completedAt,
  });

  factory ObjectiveWithProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$ObjectiveWithProgressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ObjectiveWithProgressResponseToJson(this);
}
