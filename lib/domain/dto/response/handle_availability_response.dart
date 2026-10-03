import 'package:json_annotation/json_annotation.dart';

part 'handle_availability_response.g.dart';

@JsonSerializable()
class HandleAvailabilityResponse {
  final String handle;
  final bool available;
  final String? reason;

  const HandleAvailabilityResponse({
    required this.handle,
    required this.available,
    this.reason,
  });

  factory HandleAvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      _$HandleAvailabilityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HandleAvailabilityResponseToJson(this);
}

abstract final class VenueHandleReason {
  static const String invalidFormat = 'INVALID_FORMAT';

  static const String reserved = 'RESERVED';

  static const String taken = 'TAKEN';

  static const String cooldown = 'COOLDOWN';
}
