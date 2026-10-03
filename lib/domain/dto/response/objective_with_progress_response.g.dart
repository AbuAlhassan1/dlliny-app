// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objective_with_progress_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObjectiveWithProgressResponse _$ObjectiveWithProgressResponseFromJson(
  Map<String, dynamic> json,
) => ObjectiveWithProgressResponse(
  id: json['id'] as String,
  type: $enumDecode(_$ChallengeObjectiveTypeEnumMap, json['type']),
  config: json['config'] as Map<String, dynamic>,
  points: (json['points'] as num).toInt(),
  sortOrder: (json['sortOrder'] as num).toInt(),
  titleAr: json['titleAr'] as String?,
  titleEn: json['titleEn'] as String?,
  progressValue: (json['progressValue'] as num?)?.toInt(),
  target: (json['target'] as num).toInt(),
  completed: json['completed'] as bool,
  completedAt: json['completedAt'] as String?,
);

Map<String, dynamic> _$ObjectiveWithProgressResponseToJson(
  ObjectiveWithProgressResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': _$ChallengeObjectiveTypeEnumMap[instance.type]!,
  'config': instance.config,
  'points': instance.points,
  'sortOrder': instance.sortOrder,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'progressValue': instance.progressValue,
  'target': instance.target,
  'completed': instance.completed,
  'completedAt': instance.completedAt,
};

const _$ChallengeObjectiveTypeEnumMap = {
  ChallengeObjectiveType.visitBranch: 'VISIT_BRANCH',
  ChallengeObjectiveType.createHangout: 'CREATE_HANGOUT',
  ChallengeObjectiveType.inviteFriends: 'INVITE_FRIENDS',
  ChallengeObjectiveType.postCount: 'POST_COUNT',
  ChallengeObjectiveType.memoryCount: 'MEMORY_COUNT',
  ChallengeObjectiveType.followVenue: 'FOLLOW_VENUE',
  ChallengeObjectiveType.reviewVenue: 'REVIEW_VENUE',
};
