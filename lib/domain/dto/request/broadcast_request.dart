import 'package:json_annotation/json_annotation.dart';

part 'broadcast_request.g.dart';

enum BroadcastAudienceType {
  user,

  venue,

  city,

  district,
}

@JsonSerializable(includeIfNull: false)
class BroadcastRequest {
  @JsonKey(toJson: _audienceTypeToJson, fromJson: _audienceTypeFromJson)
  final BroadcastAudienceType audienceType;

  final String audienceTargetId;

  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  final String? deepLink;

  final bool confirm;

  const BroadcastRequest({
    required this.audienceType,
    required this.audienceTargetId,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    this.deepLink,
    this.confirm = false,
  });

  factory BroadcastRequest.fromJson(Map<String, dynamic> json) =>
      _$BroadcastRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BroadcastRequestToJson(this);
}

String _audienceTypeToJson(BroadcastAudienceType t) => t.name.toUpperCase();
BroadcastAudienceType _audienceTypeFromJson(String s) =>
    BroadcastAudienceType.values.firstWhere(
      (e) => e.name.toUpperCase() == s.toUpperCase(),
      orElse: () => BroadcastAudienceType.user,
    );
