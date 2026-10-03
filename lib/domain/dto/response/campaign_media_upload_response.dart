import 'package:json_annotation/json_annotation.dart';

part 'campaign_media_upload_response.g.dart';

@JsonSerializable()
class CampaignMediaUploadResponse {
  final String uploadUrl;

  final String key;

  const CampaignMediaUploadResponse({
    required this.uploadUrl,
    required this.key,
  });

  factory CampaignMediaUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$CampaignMediaUploadResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$CampaignMediaUploadResponseToJson(this);
}
