// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_creative_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignCreativePayload _$CampaignCreativePayloadFromJson(
  Map<String, dynamic> json,
) => CampaignCreativePayload(
  sourceType: json['sourceType'] as String,
  sourcePostId: json['sourcePostId'] as String?,
  sourceHangoutId: json['sourceHangoutId'] as String?,
  mediaKey: json['mediaKey'] as String?,
  mediaType: json['mediaType'] as String?,
  caption: json['caption'] as String?,
  ctaText: json['ctaText'] as String?,
  ctaUrl: json['ctaUrl'] as String?,
);

Map<String, dynamic> _$CampaignCreativePayloadToJson(
  CampaignCreativePayload instance,
) => <String, dynamic>{
  'sourceType': instance.sourceType,
  'sourcePostId': ?instance.sourcePostId,
  'sourceHangoutId': ?instance.sourceHangoutId,
  'mediaKey': ?instance.mediaKey,
  'mediaType': ?instance.mediaType,
  'caption': ?instance.caption,
  'ctaText': ?instance.ctaText,
  'ctaUrl': ?instance.ctaUrl,
};
