import 'package:json_annotation/json_annotation.dart';

import '../request/broadcast_request.dart';

part 'audience_preview_response.g.dart';

@JsonSerializable()
class AudiencePreviewResponse {
  @JsonKey(toJson: _audienceTypeToJson, fromJson: _audienceTypeFromJson)
  final BroadcastAudienceType audienceType;

  final String audienceTargetId;
  final int count;
  final bool exceedsCallerCap;

  final int hardCap;

  const AudiencePreviewResponse({
    required this.audienceType,
    required this.audienceTargetId,
    required this.count,
    required this.exceedsCallerCap,
    required this.hardCap,
  });

  factory AudiencePreviewResponse.fromJson(Map<String, dynamic> json) =>
      _$AudiencePreviewResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AudiencePreviewResponseToJson(this);
}

String _audienceTypeToJson(BroadcastAudienceType t) => t.name.toUpperCase();
BroadcastAudienceType _audienceTypeFromJson(String s) =>
    BroadcastAudienceType.values.firstWhere(
      (e) => e.name.toUpperCase() == s.toUpperCase(),
      orElse: () => BroadcastAudienceType.user,
    );
