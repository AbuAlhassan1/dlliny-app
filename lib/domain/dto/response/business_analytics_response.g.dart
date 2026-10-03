// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_analytics_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuzzAnalyticsResponse _$BuzzAnalyticsResponseFromJson(
  Map<String, dynamic> json,
) => BuzzAnalyticsResponse(
  buzzScore: (json['buzzScore'] as num).toDouble(),
  rankInCohort: (json['rankInCohort'] as num?)?.toInt(),
  cohortSize: (json['cohortSize'] as num?)?.toInt(),
  deltaFromPrev: (json['deltaFromPrev'] as num?)?.toDouble(),
  weekStart: json['weekStart'] as String,
  trend: (json['trend'] as List<dynamic>)
      .map((e) => BuzzTrendPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuzzAnalyticsResponseToJson(
  BuzzAnalyticsResponse instance,
) => <String, dynamic>{
  'buzzScore': instance.buzzScore,
  'rankInCohort': instance.rankInCohort,
  'cohortSize': instance.cohortSize,
  'deltaFromPrev': instance.deltaFromPrev,
  'weekStart': instance.weekStart,
  'trend': instance.trend.map((e) => e.toJson()).toList(),
};

BuzzTrendPoint _$BuzzTrendPointFromJson(Map<String, dynamic> json) =>
    BuzzTrendPoint(
      weekStart: json['weekStart'] as String,
      buzzScore: (json['buzzScore'] as num).toDouble(),
      rankInCohort: (json['rankInCohort'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BuzzTrendPointToJson(BuzzTrendPoint instance) =>
    <String, dynamic>{
      'weekStart': instance.weekStart,
      'buzzScore': instance.buzzScore,
      'rankInCohort': instance.rankInCohort,
    };

FootfallHeatmapResponse _$FootfallHeatmapResponseFromJson(
  Map<String, dynamic> json,
) => FootfallHeatmapResponse(
  cells: (json['cells'] as List<dynamic>)
      .map((e) => FootfallCell.fromJson(e as Map<String, dynamic>))
      .toList(),
  maxCount: (json['maxCount'] as num).toInt(),
  privacyFloorApplied: json['privacyFloorApplied'] as bool,
);

Map<String, dynamic> _$FootfallHeatmapResponseToJson(
  FootfallHeatmapResponse instance,
) => <String, dynamic>{
  'cells': instance.cells.map((e) => e.toJson()).toList(),
  'maxCount': instance.maxCount,
  'privacyFloorApplied': instance.privacyFloorApplied,
};

FootfallCell _$FootfallCellFromJson(Map<String, dynamic> json) => FootfallCell(
  dayOfWeek: (json['dayOfWeek'] as num).toInt(),
  hourOfDay: (json['hourOfDay'] as num).toInt(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$FootfallCellToJson(FootfallCell instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'hourOfDay': instance.hourOfDay,
      'count': instance.count,
    };

DailySeriesResponse _$DailySeriesResponseFromJson(Map<String, dynamic> json) =>
    DailySeriesResponse(
      from: json['from'] as String,
      to: json['to'] as String,
      points: (json['points'] as List<dynamic>)
          .map((e) => DailyPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DailySeriesResponseToJson(
  DailySeriesResponse instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'points': instance.points.map((e) => e.toJson()).toList(),
};

DailyPoint _$DailyPointFromJson(Map<String, dynamic> json) => DailyPoint(
  date: json['date'] as String,
  memoryCount: (json['memoryCount'] as num).toInt(),
  memoryMentionCount: (json['memoryMentionCount'] as num).toInt(),
  postCount: (json['postCount'] as num).toInt(),
  hangoutsCreated: (json['hangoutsCreated'] as num).toInt(),
  hangoutAttendees: (json['hangoutAttendees'] as num).toInt(),
  newFollowers: (json['newFollowers'] as num).toInt(),
  reviewCount: (json['reviewCount'] as num).toInt(),
  reviewRatingSum: (json['reviewRatingSum'] as num).toDouble(),
  feedImpressions: (json['feedImpressions'] as num).toInt(),
  mapImpressions: (json['mapImpressions'] as num).toInt(),
  profileViews: (json['profileViews'] as num).toInt(),
);

Map<String, dynamic> _$DailyPointToJson(DailyPoint instance) =>
    <String, dynamic>{
      'date': instance.date,
      'memoryCount': instance.memoryCount,
      'memoryMentionCount': instance.memoryMentionCount,
      'postCount': instance.postCount,
      'hangoutsCreated': instance.hangoutsCreated,
      'hangoutAttendees': instance.hangoutAttendees,
      'newFollowers': instance.newFollowers,
      'reviewCount': instance.reviewCount,
      'reviewRatingSum': instance.reviewRatingSum,
      'feedImpressions': instance.feedImpressions,
      'mapImpressions': instance.mapImpressions,
      'profileViews': instance.profileViews,
    };

AnalyticsCohort _$AnalyticsCohortFromJson(Map<String, dynamic> json) =>
    AnalyticsCohort(
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryNameAr: json['categoryNameAr'] as String?,
      categoryNameEn: json['categoryNameEn'] as String?,
      districtId: (json['districtId'] as num?)?.toInt(),
      districtNameAr: json['districtNameAr'] as String?,
      districtNameEn: json['districtNameEn'] as String?,
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$AnalyticsCohortToJson(AnalyticsCohort instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryNameAr': instance.categoryNameAr,
      'categoryNameEn': instance.categoryNameEn,
      'districtId': instance.districtId,
      'districtNameAr': instance.districtNameAr,
      'districtNameEn': instance.districtNameEn,
      'size': instance.size,
    };

CategoryLeaderboardResponse _$CategoryLeaderboardResponseFromJson(
  Map<String, dynamic> json,
) => CategoryLeaderboardResponse(
  weekStart: json['weekStart'] as String,
  cohort: AnalyticsCohort.fromJson(json['cohort'] as Map<String, dynamic>),
  entries: (json['entries'] as List<dynamic>)
      .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CategoryLeaderboardResponseToJson(
  CategoryLeaderboardResponse instance,
) => <String, dynamic>{
  'weekStart': instance.weekStart,
  'cohort': instance.cohort.toJson(),
  'entries': instance.entries.map((e) => e.toJson()).toList(),
};

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      venueId: json['venueId'] as String,
      venueNameAr: json['venueNameAr'] as String,
      venueNameEn: json['venueNameEn'] as String,
      buzzScore: (json['buzzScore'] as num).toDouble(),
      isYou: json['isYou'] as bool,
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'venueId': instance.venueId,
      'venueNameAr': instance.venueNameAr,
      'venueNameEn': instance.venueNameEn,
      'buzzScore': instance.buzzScore,
      'isYou': instance.isYou,
    };

MoversResponse _$MoversResponseFromJson(Map<String, dynamic> json) =>
    MoversResponse(
      weekStart: json['weekStart'] as String,
      direction: json['direction'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => MoverEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MoversResponseToJson(MoversResponse instance) =>
    <String, dynamic>{
      'weekStart': instance.weekStart,
      'direction': instance.direction,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };

MoverEntry _$MoverEntryFromJson(Map<String, dynamic> json) => MoverEntry(
  venueId: json['venueId'] as String,
  venueNameAr: json['venueNameAr'] as String,
  venueNameEn: json['venueNameEn'] as String,
  buzzScore: (json['buzzScore'] as num).toDouble(),
  deltaFromPrev: (json['deltaFromPrev'] as num).toDouble(),
  rankInCohort: (json['rankInCohort'] as num?)?.toInt(),
  isYou: json['isYou'] as bool,
);

Map<String, dynamic> _$MoverEntryToJson(MoverEntry instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'venueNameAr': instance.venueNameAr,
      'venueNameEn': instance.venueNameEn,
      'buzzScore': instance.buzzScore,
      'deltaFromPrev': instance.deltaFromPrev,
      'rankInCohort': instance.rankInCohort,
      'isYou': instance.isYou,
    };

PeerBenchmarkResponse _$PeerBenchmarkResponseFromJson(
  Map<String, dynamic> json,
) => PeerBenchmarkResponse(
  from: json['from'] as String,
  to: json['to'] as String,
  cohort: AnalyticsCohort.fromJson(json['cohort'] as Map<String, dynamic>),
  metrics: (json['metrics'] as List<dynamic>)
      .map((e) => BenchmarkMetric.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PeerBenchmarkResponseToJson(
  PeerBenchmarkResponse instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'cohort': instance.cohort.toJson(),
  'metrics': instance.metrics.map((e) => e.toJson()).toList(),
};

AudienceDemographicsResponse _$AudienceDemographicsResponseFromJson(
  Map<String, dynamic> json,
) => AudienceDemographicsResponse(
  venueId: json['venueId'] as String,
  totalFollowers: (json['totalFollowers'] as num).toInt(),
  byDistrict: (json['byDistrict'] as List<dynamic>)
      .map((e) => DemographicBucket.fromJson(e as Map<String, dynamic>))
      .toList(),
  byCity: (json['byCity'] as List<dynamic>)
      .map((e) => DemographicBucket.fromJson(e as Map<String, dynamic>))
      .toList(),
  byLanguage: (json['byLanguage'] as List<dynamic>)
      .map((e) => DemographicBucket.fromJson(e as Map<String, dynamic>))
      .toList(),
  byGender: (json['byGender'] as List<dynamic>)
      .map((e) => DemographicBucket.fromJson(e as Map<String, dynamic>))
      .toList(),
  privacyFloorApplied: json['privacyFloorApplied'] as bool,
);

Map<String, dynamic> _$AudienceDemographicsResponseToJson(
  AudienceDemographicsResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'totalFollowers': instance.totalFollowers,
  'byDistrict': instance.byDistrict.map((e) => e.toJson()).toList(),
  'byCity': instance.byCity.map((e) => e.toJson()).toList(),
  'byLanguage': instance.byLanguage.map((e) => e.toJson()).toList(),
  'byGender': instance.byGender.map((e) => e.toJson()).toList(),
  'privacyFloorApplied': instance.privacyFloorApplied,
};

DemographicBucket _$DemographicBucketFromJson(Map<String, dynamic> json) =>
    DemographicBucket(
      label: json['label'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$DemographicBucketToJson(DemographicBucket instance) =>
    <String, dynamic>{'label': instance.label, 'count': instance.count};

AudienceActivityResponse _$AudienceActivityResponseFromJson(
  Map<String, dynamic> json,
) => AudienceActivityResponse(
  venueId: json['venueId'] as String,
  totalFollowers: (json['totalFollowers'] as num).toInt(),
  cells: (json['cells'] as List<dynamic>)
      .map((e) => AudienceActivityCell.fromJson(e as Map<String, dynamic>))
      .toList(),
  maxCount: (json['maxCount'] as num).toInt(),
  privacyFloorApplied: json['privacyFloorApplied'] as bool,
);

Map<String, dynamic> _$AudienceActivityResponseToJson(
  AudienceActivityResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'totalFollowers': instance.totalFollowers,
  'cells': instance.cells.map((e) => e.toJson()).toList(),
  'maxCount': instance.maxCount,
  'privacyFloorApplied': instance.privacyFloorApplied,
};

AudienceActivityCell _$AudienceActivityCellFromJson(
  Map<String, dynamic> json,
) => AudienceActivityCell(
  dayOfWeek: (json['dayOfWeek'] as num).toInt(),
  hourOfDay: (json['hourOfDay'] as num).toInt(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$AudienceActivityCellToJson(
  AudienceActivityCell instance,
) => <String, dynamic>{
  'dayOfWeek': instance.dayOfWeek,
  'hourOfDay': instance.hourOfDay,
  'count': instance.count,
};

LoyalistsResponse _$LoyalistsResponseFromJson(Map<String, dynamic> json) =>
    LoyalistsResponse(
      venueId: json['venueId'] as String,
      days: (json['days'] as num).toInt(),
      minMentions: (json['minMentions'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Loyalist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LoyalistsResponseToJson(LoyalistsResponse instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'days': instance.days,
      'minMentions': instance.minMentions,
      'page': instance.page,
      'size': instance.size,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

ConversionFunnelResponse _$ConversionFunnelResponseFromJson(
  Map<String, dynamic> json,
) => ConversionFunnelResponse(
  venueId: json['venueId'] as String,
  from: json['from'] as String,
  to: json['to'] as String,
  feedImpressions: (json['feedImpressions'] as num).toInt(),
  mapImpressions: (json['mapImpressions'] as num).toInt(),
  searchImpressions: (json['searchImpressions'] as num).toInt(),
  profileViews: (json['profileViews'] as num).toInt(),
  newFollowers: (json['newFollowers'] as num).toInt(),
  visitIntent: (json['visitIntent'] as num).toInt(),
  repeatVisitors: (json['repeatVisitors'] as num).toInt(),
  impressionsSampleRate: (json['impressionsSampleRate'] as num).toDouble(),
);

Map<String, dynamic> _$ConversionFunnelResponseToJson(
  ConversionFunnelResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'from': instance.from,
  'to': instance.to,
  'feedImpressions': instance.feedImpressions,
  'mapImpressions': instance.mapImpressions,
  'searchImpressions': instance.searchImpressions,
  'profileViews': instance.profileViews,
  'newFollowers': instance.newFollowers,
  'visitIntent': instance.visitIntent,
  'repeatVisitors': instance.repeatVisitors,
  'impressionsSampleRate': instance.impressionsSampleRate,
};

TopPostsResponse _$TopPostsResponseFromJson(Map<String, dynamic> json) =>
    TopPostsResponse(
      venueId: json['venueId'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      posts: (json['posts'] as List<dynamic>)
          .map((e) => TopPost.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TopPostsResponseToJson(TopPostsResponse instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'from': instance.from,
      'to': instance.to,
      'posts': instance.posts.map((e) => e.toJson()).toList(),
    };

TopPost _$TopPostFromJson(Map<String, dynamic> json) => TopPost(
  id: json['id'] as String,
  caption: json['caption'] as String?,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$TopPostToJson(TopPost instance) => <String, dynamic>{
  'id': instance.id,
  'caption': instance.caption,
  'thumbnailUrl': instance.thumbnailUrl,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'createdAt': instance.createdAt,
};

TopMemoriesResponse _$TopMemoriesResponseFromJson(Map<String, dynamic> json) =>
    TopMemoriesResponse(
      venueId: json['venueId'] as String,
      activeOnly: json['activeOnly'] as bool,
      own: (json['own'] as List<dynamic>)
          .map((e) => TopMemory.fromJson(e as Map<String, dynamic>))
          .toList(),
      mentioned: (json['mentioned'] as List<dynamic>)
          .map((e) => TopMemory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TopMemoriesResponseToJson(
  TopMemoriesResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'activeOnly': instance.activeOnly,
  'own': instance.own.map((e) => e.toJson()).toList(),
  'mentioned': instance.mentioned.map((e) => e.toJson()).toList(),
};

TopMemory _$TopMemoryFromJson(Map<String, dynamic> json) => TopMemory(
  id: json['id'] as String,
  contentType: json['contentType'] as String,
  mediaUrl: json['mediaUrl'] as String?,
  mediaThumbnailUrl: json['mediaThumbnailUrl'] as String?,
  textContent: json['textContent'] as String?,
  createdBy: json['createdBy'] as String,
  viewCount: (json['viewCount'] as num).toInt(),
  uniqueViewerCount: (json['uniqueViewerCount'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  expiresAt: json['expiresAt'] as String,
);

Map<String, dynamic> _$TopMemoryToJson(TopMemory instance) => <String, dynamic>{
  'id': instance.id,
  'contentType': instance.contentType,
  'mediaUrl': instance.mediaUrl,
  'mediaThumbnailUrl': instance.mediaThumbnailUrl,
  'textContent': instance.textContent,
  'createdBy': instance.createdBy,
  'viewCount': instance.viewCount,
  'uniqueViewerCount': instance.uniqueViewerCount,
  'createdAt': instance.createdAt,
  'expiresAt': instance.expiresAt,
};

ReviewTrendResponse _$ReviewTrendResponseFromJson(Map<String, dynamic> json) =>
    ReviewTrendResponse(
      venueId: json['venueId'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      totalReviews: (json['totalReviews'] as num).toInt(),
      trailingAverage: (json['trailingAverage'] as num).toDouble(),
      points: (json['points'] as List<dynamic>)
          .map((e) => ReviewTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReviewTrendResponseToJson(
  ReviewTrendResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'from': instance.from,
  'to': instance.to,
  'totalReviews': instance.totalReviews,
  'trailingAverage': instance.trailingAverage,
  'points': instance.points.map((e) => e.toJson()).toList(),
};

ReviewTrendPoint _$ReviewTrendPointFromJson(Map<String, dynamic> json) =>
    ReviewTrendPoint(
      date: json['date'] as String,
      count: (json['count'] as num).toInt(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ReviewTrendPointToJson(ReviewTrendPoint instance) =>
    <String, dynamic>{
      'date': instance.date,
      'count': instance.count,
      'averageRating': instance.averageRating,
    };

Loyalist _$LoyalistFromJson(Map<String, dynamic> json) => Loyalist(
  userId: json['userId'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  mentionCount: (json['mentionCount'] as num).toInt(),
);

Map<String, dynamic> _$LoyalistToJson(Loyalist instance) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'mentionCount': instance.mentionCount,
};

BenchmarkMetric _$BenchmarkMetricFromJson(Map<String, dynamic> json) =>
    BenchmarkMetric(
      key: json['key'] as String,
      you: (json['you'] as num).toDouble(),
      median: (json['median'] as num).toDouble(),
      p25: (json['p25'] as num).toDouble(),
      p75: (json['p75'] as num).toDouble(),
      percentileYou: (json['percentileYou'] as num).toInt(),
    );

Map<String, dynamic> _$BenchmarkMetricToJson(BenchmarkMetric instance) =>
    <String, dynamic>{
      'key': instance.key,
      'you': instance.you,
      'median': instance.median,
      'p25': instance.p25,
      'p75': instance.p75,
      'percentileYou': instance.percentileYou,
    };

HangoutFunnelResponse _$HangoutFunnelResponseFromJson(
  Map<String, dynamic> json,
) => HangoutFunnelResponse(
  from: json['from'] as String,
  to: json['to'] as String,
  hangoutsCreated: (json['hangoutsCreated'] as num).toInt(),
  invited: (json['invited'] as num).toInt(),
  accepted: (json['accepted'] as num).toInt(),
  declined: (json['declined'] as num).toInt(),
  pendingNow: (json['pendingNow'] as num).toInt(),
  acceptedAfterEvent: (json['acceptedAfterEvent'] as num).toInt(),
);

Map<String, dynamic> _$HangoutFunnelResponseToJson(
  HangoutFunnelResponse instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'hangoutsCreated': instance.hangoutsCreated,
  'invited': instance.invited,
  'accepted': instance.accepted,
  'declined': instance.declined,
  'pendingNow': instance.pendingNow,
  'acceptedAfterEvent': instance.acceptedAfterEvent,
};
