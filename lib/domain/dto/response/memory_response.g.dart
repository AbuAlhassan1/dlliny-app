// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryOwnerSummary _$MemoryOwnerSummaryFromJson(Map<String, dynamic> json) =>
    MemoryOwnerSummary(
      type: $enumDecode(_$MemoryOwnerTypeEnumMap, json['type']),
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      verified: json['verified'] as bool,
    );

Map<String, dynamic> _$MemoryOwnerSummaryToJson(MemoryOwnerSummary instance) =>
    <String, dynamic>{
      'type': _$MemoryOwnerTypeEnumMap[instance.type]!,
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'verified': instance.verified,
    };

const _$MemoryOwnerTypeEnumMap = {
  MemoryOwnerType.user: 'USER',
  MemoryOwnerType.venue: 'VENUE',
};

MemoryMentionResponse _$MemoryMentionResponseFromJson(
  Map<String, dynamic> json,
) => MemoryMentionResponse(
  type: $enumDecode(_$MemoryMentionTypeEnumMap, json['type']),
  id: json['id'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  position: json['position'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$MemoryMentionResponseToJson(
  MemoryMentionResponse instance,
) => <String, dynamic>{
  'type': _$MemoryMentionTypeEnumMap[instance.type]!,
  'id': instance.id,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'position': instance.position,
};

const _$MemoryMentionTypeEnumMap = {
  MemoryMentionType.user: 'USER',
  MemoryMentionType.venue: 'VENUE',
};

ReactionSummary _$ReactionSummaryFromJson(Map<String, dynamic> json) =>
    ReactionSummary(
      total: (json['total'] as num).toInt(),
      myEmoji: json['myEmoji'] as String?,
      buckets: (json['buckets'] as List<dynamic>)
          .map((e) => ReactionBucket.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReactionSummaryToJson(ReactionSummary instance) =>
    <String, dynamic>{
      'total': instance.total,
      'myEmoji': instance.myEmoji,
      'buckets': instance.buckets.map((e) => e.toJson()).toList(),
    };

ReactionBucket _$ReactionBucketFromJson(Map<String, dynamic> json) =>
    ReactionBucket(
      emoji: json['emoji'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$ReactionBucketToJson(ReactionBucket instance) =>
    <String, dynamic>{'emoji': instance.emoji, 'count': instance.count};

EngagementInfo _$EngagementInfoFromJson(Map<String, dynamic> json) =>
    EngagementInfo(
      type: $enumDecode(_$MemoryEngagementTypeEnumMap, json['type']),
      payload: json['payload'] as Map<String, dynamic>,
      myResponse: json['myResponse'] as Map<String, dynamic>?,
      totalResponses: (json['totalResponses'] as num).toInt(),
    );

Map<String, dynamic> _$EngagementInfoToJson(EngagementInfo instance) =>
    <String, dynamic>{
      'type': _$MemoryEngagementTypeEnumMap[instance.type]!,
      'payload': instance.payload,
      'myResponse': instance.myResponse,
      'totalResponses': instance.totalResponses,
    };

const _$MemoryEngagementTypeEnumMap = {
  MemoryEngagementType.poll: 'POLL',
  MemoryEngagementType.question: 'QUESTION',
  MemoryEngagementType.slider: 'SLIDER',
  MemoryEngagementType.quiz: 'QUIZ',
};

MemoryResponse _$MemoryResponseFromJson(Map<String, dynamic> json) =>
    MemoryResponse(
      id: json['id'] as String,
      owner: MemoryOwnerSummary.fromJson(json['owner'] as Map<String, dynamic>),
      contentType: $enumDecode(_$MemoryContentTypeEnumMap, json['contentType']),
      mediaUrl: json['mediaUrl'] as String?,
      mediaThumbnailUrl: json['mediaThumbnailUrl'] as String?,
      mediaStreamUrl: json['mediaStreamUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      backgroundColor: json['backgroundColor'] as String?,
      textContent: json['textContent'] as String?,
      textColor: json['textColor'] as String?,
      audioUrl: json['audioUrl'] as String?,
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(),
      viewCount: (json['viewCount'] as num).toInt(),
      uniqueViewerCount: (json['uniqueViewerCount'] as num).toInt(),
      viewedByMe: json['viewedByMe'] as bool,
      mine: json['mine'] as bool,
      expiresAt: json['expiresAt'] as String?,
      createdAt: json['createdAt'] as String?,
      mentions:
          (json['mentions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MemoryMentionResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      reactions: ReactionSummary.fromJson(
        json['reactions'] as Map<String, dynamic>,
      ),
      engagement: json['engagement'] == null
          ? null
          : EngagementInfo.fromJson(json['engagement'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MemoryResponseToJson(MemoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner': instance.owner.toJson(),
      'contentType': _$MemoryContentTypeEnumMap[instance.contentType]!,
      'mediaUrl': instance.mediaUrl,
      'mediaThumbnailUrl': instance.mediaThumbnailUrl,
      'mediaStreamUrl': instance.mediaStreamUrl,
      'durationSeconds': instance.durationSeconds,
      'backgroundColor': instance.backgroundColor,
      'textContent': instance.textContent,
      'textColor': instance.textColor,
      'audioUrl': instance.audioUrl,
      'audioDurationSeconds': instance.audioDurationSeconds,
      'viewCount': instance.viewCount,
      'uniqueViewerCount': instance.uniqueViewerCount,
      'viewedByMe': instance.viewedByMe,
      'mine': instance.mine,
      'expiresAt': instance.expiresAt,
      'createdAt': instance.createdAt,
      'mentions': instance.mentions.map((e) => e.toJson()).toList(),
      'reactions': instance.reactions.toJson(),
      'engagement': instance.engagement?.toJson(),
    };

const _$MemoryContentTypeEnumMap = {
  MemoryContentType.photo: 'PHOTO',
  MemoryContentType.video: 'VIDEO',
  MemoryContentType.text: 'TEXT',
};

MemoryTrayBucket _$MemoryTrayBucketFromJson(Map<String, dynamic> json) =>
    MemoryTrayBucket(
      owner: MemoryOwnerSummary.fromJson(json['owner'] as Map<String, dynamic>),
      memories: (json['memories'] as List<dynamic>)
          .map((e) => MemoryResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasUnwatched: json['hasUnwatched'] as bool,
    );

Map<String, dynamic> _$MemoryTrayBucketToJson(MemoryTrayBucket instance) =>
    <String, dynamic>{
      'owner': instance.owner.toJson(),
      'memories': instance.memories.map((e) => e.toJson()).toList(),
      'hasUnwatched': instance.hasUnwatched,
    };

MemoryViewerEntry _$MemoryViewerEntryFromJson(Map<String, dynamic> json) =>
    MemoryViewerEntry(
      userId: json['userId'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      verified: json['verified'] as bool,
      viewedAt: json['viewedAt'] as String,
      viewCount: (json['viewCount'] as num).toInt(),
    );

Map<String, dynamic> _$MemoryViewerEntryToJson(MemoryViewerEntry instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'verified': instance.verified,
      'viewedAt': instance.viewedAt,
      'viewCount': instance.viewCount,
    };

MemoryMetricsResponse _$MemoryMetricsResponseFromJson(
  Map<String, dynamic> json,
) => MemoryMetricsResponse(
  impressions: (json['impressions'] as num).toInt(),
  uniqueViewers: (json['uniqueViewers'] as num).toInt(),
  reactions: (json['reactions'] as num).toInt(),
  engagementResponses: (json['engagementResponses'] as num).toInt(),
);

Map<String, dynamic> _$MemoryMetricsResponseToJson(
  MemoryMetricsResponse instance,
) => <String, dynamic>{
  'impressions': instance.impressions,
  'uniqueViewers': instance.uniqueViewers,
  'reactions': instance.reactions,
  'engagementResponses': instance.engagementResponses,
};
