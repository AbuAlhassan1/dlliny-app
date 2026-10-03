import 'package:json_annotation/json_annotation.dart';

import '../api_response.dart';
import 'venue_response.dart';

part 'intent_venues_response.g.dart';

@JsonSerializable(explicitToJson: true)
class IntentVenuesResponse {
  final bool hasNoMatches;
  final PagedResponse<VenueSummaryResponse> venues;

  const IntentVenuesResponse({
    required this.hasNoMatches,
    required this.venues,
  });

  factory IntentVenuesResponse.fromJson(Map<String, dynamic> json) =>
      _$IntentVenuesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$IntentVenuesResponseToJson(this);
}
