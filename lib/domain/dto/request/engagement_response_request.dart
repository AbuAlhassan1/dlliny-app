import 'package:json_annotation/json_annotation.dart';

part 'engagement_response_request.g.dart';

@JsonSerializable()
class EngagementResponseRequest {
  final Map<String, dynamic> response;

  const EngagementResponseRequest({required this.response});

  factory EngagementResponseRequest.fromJson(Map<String, dynamic> json) =>
      _$EngagementResponseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EngagementResponseRequestToJson(this);
}
