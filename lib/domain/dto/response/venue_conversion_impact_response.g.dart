// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_conversion_impact_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VenueConversionImpactResponse _$VenueConversionImpactResponseFromJson(
  Map<String, dynamic> json,
) => VenueConversionImpactResponse(
  venueId: json['venueId'] as String,
  currentlyOnlineOnly: json['currentlyOnlineOnly'] as bool,
  upcomingHangoutCount: (json['upcomingHangoutCount'] as num).toInt(),
  activeOrderCount: (json['activeOrderCount'] as num).toInt(),
  branchCount: (json['branchCount'] as num).toInt(),
  warningsAr: (json['warningsAr'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  warningsEn: (json['warningsEn'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  safeToConvertOffline: json['safeToConvertOffline'] as bool,
);

Map<String, dynamic> _$VenueConversionImpactResponseToJson(
  VenueConversionImpactResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'currentlyOnlineOnly': instance.currentlyOnlineOnly,
  'upcomingHangoutCount': instance.upcomingHangoutCount,
  'activeOrderCount': instance.activeOrderCount,
  'branchCount': instance.branchCount,
  'warningsAr': instance.warningsAr,
  'warningsEn': instance.warningsEn,
  'safeToConvertOffline': instance.safeToConvertOffline,
};
