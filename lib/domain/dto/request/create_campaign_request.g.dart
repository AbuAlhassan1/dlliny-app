// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_campaign_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCampaignRequest _$CreateCampaignRequestFromJson(
  Map<String, dynamic> json,
) => CreateCampaignRequest(
  venueId: json['venueId'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  budget: (json['budget'] as num).toDouble(),
  startsAt: json['startsAt'] as String?,
  endsAt: json['endsAt'] as String?,
  targetDistricts: (json['targetDistricts'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  targetCategories: (json['targetCategories'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  creative: CampaignCreativePayload.fromJson(
    json['creative'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CreateCampaignRequestToJson(
  CreateCampaignRequest instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'name': instance.name,
  'type': instance.type,
  'budget': instance.budget,
  'startsAt': ?instance.startsAt,
  'endsAt': ?instance.endsAt,
  'targetDistricts': ?instance.targetDistricts,
  'targetCategories': ?instance.targetCategories,
  'creative': instance.creative.toJson(),
};
