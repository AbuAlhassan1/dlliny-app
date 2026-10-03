import 'package:json_annotation/json_annotation.dart';

part 'venue_conversion_impact_response.g.dart';

@JsonSerializable()
class VenueConversionImpactResponse {
  final String venueId;
  final bool currentlyOnlineOnly;

  final int upcomingHangoutCount;

  final int activeOrderCount;

  final int branchCount;

  final List<String> warningsAr;
  final List<String> warningsEn;

  final bool safeToConvertOffline;

  const VenueConversionImpactResponse({
    required this.venueId,
    required this.currentlyOnlineOnly,
    required this.upcomingHangoutCount,
    required this.activeOrderCount,
    required this.branchCount,
    required this.warningsAr,
    required this.warningsEn,
    required this.safeToConvertOffline,
  });

  factory VenueConversionImpactResponse.fromJson(Map<String, dynamic> json) =>
      _$VenueConversionImpactResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$VenueConversionImpactResponseToJson(this);
}
