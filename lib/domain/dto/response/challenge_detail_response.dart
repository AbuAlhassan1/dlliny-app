import 'package:json_annotation/json_annotation.dart';

import 'challenge_enums.dart';
import 'objective_with_progress_response.dart';
import 'user_challenge_progress_response.dart';

part 'challenge_detail_response.g.dart';

@JsonSerializable()
class ChallengeDetailResponse {
  final String id;
  final ChallengeKind kind;
  final ChallengeAudience audience;
  final ChallengeCadence cadence;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? iconUrl;
  final String startsAt;
  final String? endsAt;
  final int bonusPoints;
  final int? requiredObjectiveCount;

  final String? venueId;
  final String? venueNameAr;
  final String? venueNameEn;

  final UserChallengeProgressResponse? myProgress;
  final List<ObjectiveWithProgressResponse> objectives;

  const ChallengeDetailResponse({
    required this.id,
    required this.kind,
    required this.audience,
    required this.cadence,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.iconUrl,
    required this.startsAt,
    this.endsAt,
    required this.bonusPoints,
    this.requiredObjectiveCount,
    this.venueId,
    this.venueNameAr,
    this.venueNameEn,
    this.myProgress,
    required this.objectives,
  });

  factory ChallengeDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ChallengeDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeDetailResponseToJson(this);
}
