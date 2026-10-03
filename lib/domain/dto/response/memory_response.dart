import 'package:json_annotation/json_annotation.dart';

import 'memory_enums.dart';

part 'memory_response.g.dart';

@JsonSerializable()
class MemoryOwnerSummary {
  final MemoryOwnerType type;
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final bool verified;

  const MemoryOwnerSummary({
    required this.type,
    required this.id,
    this.displayName,
    this.avatarUrl,
    required this.verified,
  });

  factory MemoryOwnerSummary.fromJson(Map<String, dynamic> json) =>
      _$MemoryOwnerSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryOwnerSummaryToJson(this);
}

@JsonSerializable()
class MemoryMentionResponse {
  final MemoryMentionType type;
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final Map<String, dynamic>? position;

  const MemoryMentionResponse({
    required this.type,
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.position,
  });

  factory MemoryMentionResponse.fromJson(Map<String, dynamic> json) =>
      _$MemoryMentionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryMentionResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReactionSummary {
  final int total;
  final String? myEmoji;
  final List<ReactionBucket> buckets;

  const ReactionSummary({
    required this.total,
    this.myEmoji,
    required this.buckets,
  });

  factory ReactionSummary.fromJson(Map<String, dynamic> json) =>
      _$ReactionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionSummaryToJson(this);
}

@JsonSerializable()
class ReactionBucket {
  final String emoji;
  final int count;

  const ReactionBucket({required this.emoji, required this.count});

  factory ReactionBucket.fromJson(Map<String, dynamic> json) =>
      _$ReactionBucketFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionBucketToJson(this);
}

@JsonSerializable()
class EngagementInfo {
  final MemoryEngagementType type;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? myResponse;
  final int totalResponses;

  const EngagementInfo({
    required this.type,
    required this.payload,
    this.myResponse,
    required this.totalResponses,
  });

  factory EngagementInfo.fromJson(Map<String, dynamic> json) =>
      _$EngagementInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EngagementInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MemoryResponse {
  final String id;
  final MemoryOwnerSummary owner;
  final MemoryContentType contentType;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;

  final String? mediaStreamUrl;
  final int? durationSeconds;
  final String? backgroundColor;
  final String? textContent;
  final String? textColor;
  final String? audioUrl;
  final int? audioDurationSeconds;
  final int viewCount;
  final int uniqueViewerCount;
  final bool viewedByMe;
  final bool mine;
  final String? expiresAt;
  final String? createdAt;
  @JsonKey(defaultValue: <MemoryMentionResponse>[])
  final List<MemoryMentionResponse> mentions;
  final ReactionSummary reactions;
  final EngagementInfo? engagement;

  const MemoryResponse({
    required this.id,
    required this.owner,
    required this.contentType,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaStreamUrl,
    this.durationSeconds,
    this.backgroundColor,
    this.textContent,
    this.textColor,
    this.audioUrl,
    this.audioDurationSeconds,
    required this.viewCount,
    required this.uniqueViewerCount,
    required this.viewedByMe,
    required this.mine,
    this.expiresAt,
    this.createdAt,
    this.mentions = const [],
    required this.reactions,
    this.engagement,
  });

  factory MemoryResponse.fromJson(Map<String, dynamic> json) =>
      _$MemoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MemoryTrayBucket {
  final MemoryOwnerSummary owner;
  final List<MemoryResponse> memories;
  final bool hasUnwatched;

  const MemoryTrayBucket({
    required this.owner,
    required this.memories,
    required this.hasUnwatched,
  });

  factory MemoryTrayBucket.fromJson(Map<String, dynamic> json) =>
      _$MemoryTrayBucketFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryTrayBucketToJson(this);
}

@JsonSerializable()
class MemoryViewerEntry {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool verified;
  final String viewedAt;
  final int viewCount;

  const MemoryViewerEntry({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.verified,
    required this.viewedAt,
    required this.viewCount,
  });

  factory MemoryViewerEntry.fromJson(Map<String, dynamic> json) =>
      _$MemoryViewerEntryFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryViewerEntryToJson(this);
}

@JsonSerializable()
class MemoryMetricsResponse {
  final int impressions;
  final int uniqueViewers;
  final int reactions;
  final int engagementResponses;

  const MemoryMetricsResponse({
    required this.impressions,
    required this.uniqueViewers,
    required this.reactions,
    required this.engagementResponses,
  });

  factory MemoryMetricsResponse.fromJson(Map<String, dynamic> json) =>
      _$MemoryMetricsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryMetricsResponseToJson(this);
}
