import 'package:json_annotation/json_annotation.dart';

part 'business_analytics_response.g.dart';

@JsonSerializable(explicitToJson: true)
class BuzzAnalyticsResponse {
  final double buzzScore;
  final int? rankInCohort;
  final int? cohortSize;
  final double? deltaFromPrev;
  final String weekStart;
  final List<BuzzTrendPoint> trend;

  const BuzzAnalyticsResponse({
    required this.buzzScore,
    this.rankInCohort,
    this.cohortSize,
    this.deltaFromPrev,
    required this.weekStart,
    required this.trend,
  });

  factory BuzzAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      _$BuzzAnalyticsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BuzzAnalyticsResponseToJson(this);
}

@JsonSerializable()
class BuzzTrendPoint {
  final String weekStart;
  final double buzzScore;
  final int? rankInCohort;

  const BuzzTrendPoint({
    required this.weekStart,
    required this.buzzScore,
    this.rankInCohort,
  });

  factory BuzzTrendPoint.fromJson(Map<String, dynamic> json) =>
      _$BuzzTrendPointFromJson(json);

  Map<String, dynamic> toJson() => _$BuzzTrendPointToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FootfallHeatmapResponse {
  final List<FootfallCell> cells;
  final int maxCount;
  final bool privacyFloorApplied;

  const FootfallHeatmapResponse({
    required this.cells,
    required this.maxCount,
    required this.privacyFloorApplied,
  });

  factory FootfallHeatmapResponse.fromJson(Map<String, dynamic> json) =>
      _$FootfallHeatmapResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FootfallHeatmapResponseToJson(this);
}

@JsonSerializable()
class FootfallCell {
  final int dayOfWeek;
  final int hourOfDay;
  final int count;

  const FootfallCell({
    required this.dayOfWeek,
    required this.hourOfDay,
    required this.count,
  });

  factory FootfallCell.fromJson(Map<String, dynamic> json) =>
      _$FootfallCellFromJson(json);

  Map<String, dynamic> toJson() => _$FootfallCellToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DailySeriesResponse {
  final String from;
  final String to;
  final List<DailyPoint> points;

  const DailySeriesResponse({
    required this.from,
    required this.to,
    required this.points,
  });

  factory DailySeriesResponse.fromJson(Map<String, dynamic> json) =>
      _$DailySeriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DailySeriesResponseToJson(this);
}

@JsonSerializable()
class DailyPoint {
  final String date;
  final int memoryCount;
  final int memoryMentionCount;
  final int postCount;
  final int hangoutsCreated;
  final int hangoutAttendees;
  final int newFollowers;
  final int reviewCount;
  final double reviewRatingSum;
  final int feedImpressions;
  final int mapImpressions;
  final int profileViews;

  const DailyPoint({
    required this.date,
    required this.memoryCount,
    required this.memoryMentionCount,
    required this.postCount,
    required this.hangoutsCreated,
    required this.hangoutAttendees,
    required this.newFollowers,
    required this.reviewCount,
    required this.reviewRatingSum,
    required this.feedImpressions,
    required this.mapImpressions,
    required this.profileViews,
  });

  factory DailyPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyPointFromJson(json);

  Map<String, dynamic> toJson() => _$DailyPointToJson(this);
}

@JsonSerializable()
class AnalyticsCohort {
  final int? categoryId;
  final String? categoryNameAr;
  final String? categoryNameEn;
  final int? districtId;
  final String? districtNameAr;
  final String? districtNameEn;
  final int size;

  const AnalyticsCohort({
    this.categoryId,
    this.categoryNameAr,
    this.categoryNameEn,
    this.districtId,
    this.districtNameAr,
    this.districtNameEn,
    required this.size,
  });

  factory AnalyticsCohort.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsCohortFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsCohortToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CategoryLeaderboardResponse {
  final String weekStart;
  final AnalyticsCohort cohort;
  final List<LeaderboardEntry> entries;

  const CategoryLeaderboardResponse({
    required this.weekStart,
    required this.cohort,
    required this.entries,
  });

  factory CategoryLeaderboardResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryLeaderboardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryLeaderboardResponseToJson(this);
}

@JsonSerializable()
class LeaderboardEntry {
  final int rank;
  final String venueId;
  final String venueNameAr;
  final String venueNameEn;
  final double buzzScore;
  final bool isYou;

  const LeaderboardEntry({
    required this.rank,
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    required this.buzzScore,
    required this.isYou,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MoversResponse {
  final String weekStart;
  final String direction;
  final List<MoverEntry> entries;

  const MoversResponse({
    required this.weekStart,
    required this.direction,
    required this.entries,
  });

  factory MoversResponse.fromJson(Map<String, dynamic> json) =>
      _$MoversResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MoversResponseToJson(this);
}

@JsonSerializable()
class MoverEntry {
  final String venueId;
  final String venueNameAr;
  final String venueNameEn;
  final double buzzScore;
  final double deltaFromPrev;
  final int? rankInCohort;
  final bool isYou;

  const MoverEntry({
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    required this.buzzScore,
    required this.deltaFromPrev,
    this.rankInCohort,
    required this.isYou,
  });

  factory MoverEntry.fromJson(Map<String, dynamic> json) =>
      _$MoverEntryFromJson(json);

  Map<String, dynamic> toJson() => _$MoverEntryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PeerBenchmarkResponse {
  final String from;
  final String to;
  final AnalyticsCohort cohort;
  final List<BenchmarkMetric> metrics;

  const PeerBenchmarkResponse({
    required this.from,
    required this.to,
    required this.cohort,
    required this.metrics,
  });

  factory PeerBenchmarkResponse.fromJson(Map<String, dynamic> json) =>
      _$PeerBenchmarkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PeerBenchmarkResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AudienceDemographicsResponse {
  final String venueId;
  final int totalFollowers;
  final List<DemographicBucket> byDistrict;
  final List<DemographicBucket> byCity;
  final List<DemographicBucket> byLanguage;
  final List<DemographicBucket> byGender;
  final bool privacyFloorApplied;

  const AudienceDemographicsResponse({
    required this.venueId,
    required this.totalFollowers,
    required this.byDistrict,
    required this.byCity,
    required this.byLanguage,
    required this.byGender,
    required this.privacyFloorApplied,
  });

  factory AudienceDemographicsResponse.fromJson(Map<String, dynamic> json) =>
      _$AudienceDemographicsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AudienceDemographicsResponseToJson(this);
}

@JsonSerializable()
class DemographicBucket {
  final String label;
  final int count;

  const DemographicBucket({required this.label, required this.count});

  factory DemographicBucket.fromJson(Map<String, dynamic> json) =>
      _$DemographicBucketFromJson(json);

  Map<String, dynamic> toJson() => _$DemographicBucketToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AudienceActivityResponse {
  final String venueId;
  final int totalFollowers;
  final List<AudienceActivityCell> cells;
  final int maxCount;
  final bool privacyFloorApplied;

  const AudienceActivityResponse({
    required this.venueId,
    required this.totalFollowers,
    required this.cells,
    required this.maxCount,
    required this.privacyFloorApplied,
  });

  factory AudienceActivityResponse.fromJson(Map<String, dynamic> json) =>
      _$AudienceActivityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AudienceActivityResponseToJson(this);
}

@JsonSerializable()
class AudienceActivityCell {
  final int dayOfWeek;
  final int hourOfDay;
  final int count;

  const AudienceActivityCell({
    required this.dayOfWeek,
    required this.hourOfDay,
    required this.count,
  });

  factory AudienceActivityCell.fromJson(Map<String, dynamic> json) =>
      _$AudienceActivityCellFromJson(json);

  Map<String, dynamic> toJson() => _$AudienceActivityCellToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LoyalistsResponse {
  final String venueId;
  final int days;
  final int minMentions;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final List<Loyalist> items;

  const LoyalistsResponse({
    required this.venueId,
    required this.days,
    required this.minMentions,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.items,
  });

  factory LoyalistsResponse.fromJson(Map<String, dynamic> json) =>
      _$LoyalistsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoyalistsResponseToJson(this);
}

@JsonSerializable()
class ConversionFunnelResponse {
  final String venueId;
  final String from;
  final String to;
  final int feedImpressions;
  final int mapImpressions;
  final int searchImpressions;
  final int profileViews;
  final int newFollowers;
  final int visitIntent;
  final int repeatVisitors;
  final double impressionsSampleRate;

  const ConversionFunnelResponse({
    required this.venueId,
    required this.from,
    required this.to,
    required this.feedImpressions,
    required this.mapImpressions,
    required this.searchImpressions,
    required this.profileViews,
    required this.newFollowers,
    required this.visitIntent,
    required this.repeatVisitors,
    required this.impressionsSampleRate,
  });

  factory ConversionFunnelResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversionFunnelResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConversionFunnelResponseToJson(this);

  int get totalImpressions =>
      feedImpressions + mapImpressions + searchImpressions;
}

@JsonSerializable(explicitToJson: true)
class TopPostsResponse {
  final String venueId;
  final String from;
  final String to;
  final List<TopPost> posts;

  const TopPostsResponse({
    required this.venueId,
    required this.from,
    required this.to,
    required this.posts,
  });

  factory TopPostsResponse.fromJson(Map<String, dynamic> json) =>
      _$TopPostsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TopPostsResponseToJson(this);
}

@JsonSerializable()
class TopPost {
  final String id;
  final String? caption;
  final String? thumbnailUrl;
  final int likesCount;
  final int commentsCount;
  final String createdAt;

  const TopPost({
    required this.id,
    this.caption,
    this.thumbnailUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  factory TopPost.fromJson(Map<String, dynamic> json) => _$TopPostFromJson(json);
  Map<String, dynamic> toJson() => _$TopPostToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TopMemoriesResponse {
  final String venueId;
  final bool activeOnly;
  final List<TopMemory> own;
  final List<TopMemory> mentioned;

  const TopMemoriesResponse({
    required this.venueId,
    required this.activeOnly,
    required this.own,
    required this.mentioned,
  });

  factory TopMemoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$TopMemoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TopMemoriesResponseToJson(this);
}

@JsonSerializable()
class TopMemory {
  final String id;
  final String contentType;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? textContent;
  final String createdBy;
  final int viewCount;
  final int uniqueViewerCount;
  final String createdAt;
  final String expiresAt;

  const TopMemory({
    required this.id,
    required this.contentType,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.textContent,
    required this.createdBy,
    required this.viewCount,
    required this.uniqueViewerCount,
    required this.createdAt,
    required this.expiresAt,
  });

  factory TopMemory.fromJson(Map<String, dynamic> json) =>
      _$TopMemoryFromJson(json);
  Map<String, dynamic> toJson() => _$TopMemoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReviewTrendResponse {
  final String venueId;
  final String from;
  final String to;
  final int totalReviews;
  final double trailingAverage;
  final List<ReviewTrendPoint> points;

  const ReviewTrendResponse({
    required this.venueId,
    required this.from,
    required this.to,
    required this.totalReviews,
    required this.trailingAverage,
    required this.points,
  });

  factory ReviewTrendResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewTrendResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewTrendResponseToJson(this);
}

@JsonSerializable()
class ReviewTrendPoint {
  final String date;
  final int count;
  final double? averageRating;

  const ReviewTrendPoint({
    required this.date,
    required this.count,
    this.averageRating,
  });

  factory ReviewTrendPoint.fromJson(Map<String, dynamic> json) =>
      _$ReviewTrendPointFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewTrendPointToJson(this);
}

@JsonSerializable()
class Loyalist {
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int mentionCount;

  const Loyalist({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.mentionCount,
  });

  factory Loyalist.fromJson(Map<String, dynamic> json) =>
      _$LoyalistFromJson(json);

  Map<String, dynamic> toJson() => _$LoyalistToJson(this);
}

@JsonSerializable()
class BenchmarkMetric {
  final String key;
  final double you;
  final double median;
  final double p25;
  final double p75;
  final int percentileYou;

  const BenchmarkMetric({
    required this.key,
    required this.you,
    required this.median,
    required this.p25,
    required this.p75,
    required this.percentileYou,
  });

  factory BenchmarkMetric.fromJson(Map<String, dynamic> json) =>
      _$BenchmarkMetricFromJson(json);

  Map<String, dynamic> toJson() => _$BenchmarkMetricToJson(this);
}

@JsonSerializable()
class HangoutFunnelResponse {
  final String from;
  final String to;
  final int hangoutsCreated;
  final int invited;
  final int accepted;
  final int declined;
  final int pendingNow;
  final int acceptedAfterEvent;

  const HangoutFunnelResponse({
    required this.from,
    required this.to,
    required this.hangoutsCreated,
    required this.invited,
    required this.accepted,
    required this.declined,
    required this.pendingNow,
    required this.acceptedAfterEvent,
  });

  factory HangoutFunnelResponse.fromJson(Map<String, dynamic> json) =>
      _$HangoutFunnelResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HangoutFunnelResponseToJson(this);
}
