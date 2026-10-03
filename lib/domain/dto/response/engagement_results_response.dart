import 'package:json_annotation/json_annotation.dart';

import 'memory_enums.dart';

part 'engagement_results_response.g.dart';

@JsonSerializable(explicitToJson: true)
class EngagementResultsResponse {
  final MemoryEngagementType type;
  final int totalResponses;
  final List<EngagementOptionBucket>? optionCounts;
  final int? correctOptionIndex;
  final int? correctCount;
  final double? sliderAverage;
  final List<int>? sliderDistribution;
  final PagedResponseEnvelope responses;

  const EngagementResultsResponse({
    required this.type,
    required this.totalResponses,
    this.optionCounts,
    this.correctOptionIndex,
    this.correctCount,
    this.sliderAverage,
    this.sliderDistribution,
    required this.responses,
  });

  factory EngagementResultsResponse.fromJson(Map<String, dynamic> json) =>
      _$EngagementResultsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EngagementResultsResponseToJson(this);
}

@JsonSerializable()
class EngagementOptionBucket {
  final int optionIndex;
  final int count;
  final double percentage;

  const EngagementOptionBucket({
    required this.optionIndex,
    required this.count,
    required this.percentage,
  });

  factory EngagementOptionBucket.fromJson(Map<String, dynamic> json) =>
      _$EngagementOptionBucketFromJson(json);

  Map<String, dynamic> toJson() => _$EngagementOptionBucketToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PagedResponseEnvelope {
  final List<EngagementRespondent> content;
  @JsonKey(name: 'number')
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PagedResponseEnvelope({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PagedResponseEnvelope.fromJson(Map<String, dynamic> json) =>
      _$PagedResponseEnvelopeFromJson(json);

  Map<String, dynamic> toJson() => _$PagedResponseEnvelopeToJson(this);
}

@JsonSerializable()
class EngagementRespondent {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool verified;
  final Map<String, dynamic> response;
  final String respondedAt;

  const EngagementRespondent({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.verified,
    required this.response,
    required this.respondedAt,
  });

  factory EngagementRespondent.fromJson(Map<String, dynamic> json) =>
      _$EngagementRespondentFromJson(json);

  Map<String, dynamic> toJson() => _$EngagementRespondentToJson(this);
}
