import 'package:json_annotation/json_annotation.dart';

import 'challenge_enums.dart';
import 'user_challenge_progress_response.dart';

part 'challenge_list_item_response.g.dart';

@JsonSerializable()
class ChallengeListItemResponse {
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

  final int totalObjectiveCount;

  final String? venueId;
  final String? venueNameAr;
  final String? venueNameEn;

  final UserChallengeProgressResponse? myProgress;

  const ChallengeListItemResponse({
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
    required this.totalObjectiveCount,
    this.venueId,
    this.venueNameAr,
    this.venueNameEn,
    this.myProgress,
  });

  factory ChallengeListItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ChallengeListItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeListItemResponseToJson(this);
}
