import 'package:json_annotation/json_annotation.dart';

part 'proximity_ping_request.g.dart';

@JsonSerializable()
class ProximityPingRequest {
  final double latitude;
  final double longitude;

  const ProximityPingRequest({required this.latitude, required this.longitude});

  factory ProximityPingRequest.fromJson(Map<String, dynamic> json) =>
      _$ProximityPingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProximityPingRequestToJson(this);
}
