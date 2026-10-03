// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeDetailResponse _$ChallengeDetailResponseFromJson(
  Map<String, dynamic> json,
) => ChallengeDetailResponse(
  id: json['id'] as String,
  kind: $enumDecode(_$ChallengeKindEnumMap, json['kind']),
  audience: $enumDecode(_$ChallengeAudienceEnumMap, json['audience']),
  cadence: $enumDecode(_$ChallengeCadenceEnumMap, json['cadence']),
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String,
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  iconUrl: json['iconUrl'] as String?,
  startsAt: json['startsAt'] as String,
  endsAt: json['endsAt'] as String?,
  bonusPoints: (json['bonusPoints'] as num).toInt(),
  requiredObjectiveCount: (json['requiredObjectiveCount'] as num?)?.toInt(),
  venueId: json['venueId'] as String?,
  venueNameAr: json['venueNameAr'] as String?,
  venueNameEn: json['venueNameEn'] as String?,
  myProgress: json['myProgress'] == null
      ? null
      : UserChallengeProgressResponse.fromJson(
          json['myProgress'] as Map<String, dynamic>,
        ),
  objectives: (json['objectives'] as List<dynamic>)
      .map(
        (e) =>
            ObjectiveWithProgressResponse.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$ChallengeDetailResponseToJson(
  ChallengeDetailResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': _$ChallengeKindEnumMap[instance.kind]!,
  'audience': _$ChallengeAudienceEnumMap[instance.audience]!,
  'cadence': _$ChallengeCadenceEnumMap[instance.cadence]!,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'descriptionAr': instance.descriptionAr,
  'descriptionEn': instance.descriptionEn,
  'iconUrl': instance.iconUrl,
  'startsAt': instance.startsAt,
  'endsAt': instance.endsAt,
  'bonusPoints': instance.bonusPoints,
  'requiredObjectiveCount': instance.requiredObjectiveCount,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'myProgress': instance.myProgress,
  'objectives': instance.objectives,
};

const _$ChallengeKindEnumMap = {
  ChallengeKind.platform: 'PLATFORM',
  ChallengeKind.venue: 'VENUE',
};

const _$ChallengeAudienceEnumMap = {
  ChallengeAudience.any: 'ANY',
  ChallengeAudience.normalUsers: 'NORMAL_USERS',
  ChallengeAudience.influencers: 'INFLUENCERS',
};

const _$ChallengeCadenceEnumMap = {
  ChallengeCadence.daily: 'DAILY',
  ChallengeCadence.weekly: 'WEEKLY',
  ChallengeCadence.monthly: 'MONTHLY',
  ChallengeCadence.seasonal: 'SEASONAL',
  ChallengeCadence.special: 'SPECIAL',
};
