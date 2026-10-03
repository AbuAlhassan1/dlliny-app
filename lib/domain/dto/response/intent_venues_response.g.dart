// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intent_venues_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntentVenuesResponse _$IntentVenuesResponseFromJson(
  Map<String, dynamic> json,
) => IntentVenuesResponse(
  hasNoMatches: json['hasNoMatches'] as bool,
  venues: PagedResponse<VenueSummaryResponse>.fromJson(
    json['venues'] as Map<String, dynamic>,
    (value) => VenueSummaryResponse.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _$IntentVenuesResponseToJson(
  IntentVenuesResponse instance,
) => <String, dynamic>{
  'hasNoMatches': instance.hasNoMatches,
  'venues': instance.venues.toJson((value) => value.toJson()),
};
