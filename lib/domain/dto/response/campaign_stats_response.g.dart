// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_stats_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignStatsResponse _$CampaignStatsResponseFromJson(
  Map<String, dynamic> json,
) => CampaignStatsResponse(
  campaignId: json['campaignId'] as String,
  totalImpressions: (json['totalImpressions'] as num).toInt(),
  totalClicks: (json['totalClicks'] as num).toInt(),
  totalSpent: (json['totalSpent'] as num).toDouble(),
  budget: (json['budget'] as num).toDouble(),
  ctrPercent: (json['ctrPercent'] as num).toDouble(),
  windowStart: json['windowStart'] as String,
  dailyImpressions: (json['dailyImpressions'] as List<dynamic>)
      .map((e) => DailyImpressionPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CampaignStatsResponseToJson(
  CampaignStatsResponse instance,
) => <String, dynamic>{
  'campaignId': instance.campaignId,
  'totalImpressions': instance.totalImpressions,
  'totalClicks': instance.totalClicks,
  'totalSpent': instance.totalSpent,
  'budget': instance.budget,
  'ctrPercent': instance.ctrPercent,
  'windowStart': instance.windowStart,
  'dailyImpressions': instance.dailyImpressions.map((e) => e.toJson()).toList(),
};

DailyImpressionPoint _$DailyImpressionPointFromJson(
  Map<String, dynamic> json,
) => DailyImpressionPoint(
  day: json['day'] as String,
  impressions: (json['impressions'] as num).toInt(),
);

Map<String, dynamic> _$DailyImpressionPointToJson(
  DailyImpressionPoint instance,
) => <String, dynamic>{
  'day': instance.day,
  'impressions': instance.impressions,
};
