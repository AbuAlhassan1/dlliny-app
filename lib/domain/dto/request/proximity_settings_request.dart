import 'package:json_annotation/json_annotation.dart';

part 'proximity_settings_request.g.dart';

@JsonSerializable()
class ProximitySettingsRequest {
  final bool discoverable;

  const ProximitySettingsRequest({required this.discoverable});

  factory ProximitySettingsRequest.fromJson(Map<String, dynamic> json) =>
      _$ProximitySettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProximitySettingsRequestToJson(this);
}
