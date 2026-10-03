import 'package:hangout/domain/dto/request/campaign_creative_payload.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_campaign_request.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CreateCampaignRequest {
  final String venueId;
  final String name;

  final String type;

  final double budget;

  final String? startsAt;

  final String? endsAt;

  final List<String>? targetDistricts;
  final List<int>? targetCategories;

  final CampaignCreativePayload creative;

  const CreateCampaignRequest({
    required this.venueId,
    required this.name,
    required this.type,
    required this.budget,
    this.startsAt,
    this.endsAt,
    this.targetDistricts,
    this.targetCategories,
    required this.creative,
  });

  factory CreateCampaignRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCampaignRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCampaignRequestToJson(this);
}
