// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_challenge_progress_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserChallengeProgressResponse _$UserChallengeProgressResponseFromJson(
  Map<String, dynamic> json,
) => UserChallengeProgressResponse(
  status: $enumDecode(_$ChallengeProgressStatusEnumMap, json['status']),
  totalPointsEarned: (json['totalPointsEarned'] as num).toInt(),
  completedObjectiveCount: (json['completedObjectiveCount'] as num).toInt(),
  totalObjectiveCount: (json['totalObjectiveCount'] as num).toInt(),
  completedAt: json['completedAt'] as String?,
  joinedAt: json['joinedAt'] as String,
);

Map<String, dynamic> _$UserChallengeProgressResponseToJson(
  UserChallengeProgressResponse instance,
) => <String, dynamic>{
  'status': _$ChallengeProgressStatusEnumMap[instance.status]!,
  'totalPointsEarned': instance.totalPointsEarned,
  'completedObjectiveCount': instance.completedObjectiveCount,
  'totalObjectiveCount': instance.totalObjectiveCount,
  'completedAt': instance.completedAt,
  'joinedAt': instance.joinedAt,
};

const _$ChallengeProgressStatusEnumMap = {
  ChallengeProgressStatus.inProgress: 'IN_PROGRESS',
  ChallengeProgressStatus.completed: 'COMPLETED',
  ChallengeProgressStatus.expired: 'EXPIRED',
};
