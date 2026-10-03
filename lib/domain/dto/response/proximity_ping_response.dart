import 'package:json_annotation/json_annotation.dart';

part 'proximity_ping_response.g.dart';

@JsonSerializable()
class ProximityPingResponse {
  final bool recorded;

  const ProximityPingResponse({required this.recorded});

  factory ProximityPingResponse.fromJson(Map<String, dynamic> json) =>
      _$ProximityPingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProximityPingResponseToJson(this);
}
