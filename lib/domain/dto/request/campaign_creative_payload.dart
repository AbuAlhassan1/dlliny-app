import 'package:json_annotation/json_annotation.dart';

part 'campaign_creative_payload.g.dart';

@JsonSerializable(includeIfNull: false)
class CampaignCreativePayload {
  final String sourceType;

  final String? sourcePostId;
  final String? sourceHangoutId;

  final String? mediaKey;
  final String? mediaType;
  final String? caption;

  final String? ctaText;
  final String? ctaUrl;

  const CampaignCreativePayload({
    required this.sourceType,
    this.sourcePostId,
    this.sourceHangoutId,
    this.mediaKey,
    this.mediaType,
    this.caption,
    this.ctaText,
    this.ctaUrl,
  });

  factory CampaignCreativePayload.boostPost({
    required String postId,
    String? ctaText,
    String? ctaUrl,
  }) =>
      CampaignCreativePayload(
        sourceType: 'POST',
        sourcePostId: postId,
        ctaText: ctaText,
        ctaUrl: ctaUrl,
      );

  factory CampaignCreativePayload.boostHangout({
    required String hangoutId,
    String? ctaText,
    String? ctaUrl,
  }) =>
      CampaignCreativePayload(
        sourceType: 'HANGOUT',
        sourceHangoutId: hangoutId,
        ctaText: ctaText,
        ctaUrl: ctaUrl,
      );

  factory CampaignCreativePayload.custom({
    required String mediaKey,
    required String mediaType,
    String? caption,
    String? ctaText,
    String? ctaUrl,
  }) =>
      CampaignCreativePayload(
        sourceType: 'CUSTOM',
        mediaKey: mediaKey,
        mediaType: mediaType,
        caption: caption,
        ctaText: ctaText,
        ctaUrl: ctaUrl,
      );

  factory CampaignCreativePayload.fromJson(Map<String, dynamic> json) =>
      _$CampaignCreativePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignCreativePayloadToJson(this);
}
