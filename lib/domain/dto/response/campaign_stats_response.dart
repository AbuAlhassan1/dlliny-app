import 'package:json_annotation/json_annotation.dart';

part 'campaign_stats_response.g.dart';

@JsonSerializable(explicitToJson: true)
class CampaignStatsResponse {
  final String campaignId;
  final int totalImpressions;
  final int totalClicks;
  final double totalSpent;
  final double budget;

  final double ctrPercent;

  final String windowStart;

  final List<DailyImpressionPoint> dailyImpressions;

  const CampaignStatsResponse({
    required this.campaignId,
    required this.totalImpressions,
    required this.totalClicks,
    required this.totalSpent,
    required this.budget,
    required this.ctrPercent,
    required this.windowStart,
    required this.dailyImpressions,
  });

  factory CampaignStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$CampaignStatsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignStatsResponseToJson(this);
}

@JsonSerializable()
class DailyImpressionPoint {
  final String day;
  final int impressions;

  const DailyImpressionPoint({
    required this.day,
    required this.impressions,
  });

  factory DailyImpressionPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyImpressionPointFromJson(json);
  Map<String, dynamic> toJson() => _$DailyImpressionPointToJson(this);
}
