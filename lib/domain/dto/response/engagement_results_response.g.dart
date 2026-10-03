// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engagement_results_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EngagementResultsResponse _$EngagementResultsResponseFromJson(
  Map<String, dynamic> json,
) => EngagementResultsResponse(
  type: $enumDecode(_$MemoryEngagementTypeEnumMap, json['type']),
  totalResponses: (json['totalResponses'] as num).toInt(),
  optionCounts: (json['optionCounts'] as List<dynamic>?)
      ?.map((e) => EngagementOptionBucket.fromJson(e as Map<String, dynamic>))
      .toList(),
  correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt(),
  correctCount: (json['correctCount'] as num?)?.toInt(),
  sliderAverage: (json['sliderAverage'] as num?)?.toDouble(),
  sliderDistribution: (json['sliderDistribution'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  responses: PagedResponseEnvelope.fromJson(
    json['responses'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$EngagementResultsResponseToJson(
  EngagementResultsResponse instance,
) => <String, dynamic>{
  'type': _$MemoryEngagementTypeEnumMap[instance.type]!,
  'totalResponses': instance.totalResponses,
  'optionCounts': instance.optionCounts?.map((e) => e.toJson()).toList(),
  'correctOptionIndex': instance.correctOptionIndex,
  'correctCount': instance.correctCount,
  'sliderAverage': instance.sliderAverage,
  'sliderDistribution': instance.sliderDistribution,
  'responses': instance.responses.toJson(),
};

const _$MemoryEngagementTypeEnumMap = {
  MemoryEngagementType.poll: 'POLL',
  MemoryEngagementType.question: 'QUESTION',
  MemoryEngagementType.slider: 'SLIDER',
  MemoryEngagementType.quiz: 'QUIZ',
};

EngagementOptionBucket _$EngagementOptionBucketFromJson(
  Map<String, dynamic> json,
) => EngagementOptionBucket(
  optionIndex: (json['optionIndex'] as num).toInt(),
  count: (json['count'] as num).toInt(),
  percentage: (json['percentage'] as num).toDouble(),
);

Map<String, dynamic> _$EngagementOptionBucketToJson(
  EngagementOptionBucket instance,
) => <String, dynamic>{
  'optionIndex': instance.optionIndex,
  'count': instance.count,
  'percentage': instance.percentage,
};

PagedResponseEnvelope _$PagedResponseEnvelopeFromJson(
  Map<String, dynamic> json,
) => PagedResponseEnvelope(
  content: (json['content'] as List<dynamic>)
      .map((e) => EngagementRespondent.fromJson(e as Map<String, dynamic>))
      .toList(),
  page: (json['number'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  totalElements: (json['totalElements'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  last: json['last'] as bool,
);

Map<String, dynamic> _$PagedResponseEnvelopeToJson(
  PagedResponseEnvelope instance,
) => <String, dynamic>{
  'content': instance.content.map((e) => e.toJson()).toList(),
  'number': instance.page,
  'size': instance.size,
  'totalElements': instance.totalElements,
  'totalPages': instance.totalPages,
  'last': instance.last,
};

EngagementRespondent _$EngagementRespondentFromJson(
  Map<String, dynamic> json,
) => EngagementRespondent(
  userId: json['userId'] as String,
  username: json['username'] as String?,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  verified: json['verified'] as bool,
  response: json['response'] as Map<String, dynamic>,
  respondedAt: json['respondedAt'] as String,
);

Map<String, dynamic> _$EngagementRespondentToJson(
  EngagementRespondent instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'verified': instance.verified,
  'response': instance.response,
  'respondedAt': instance.respondedAt,
};
