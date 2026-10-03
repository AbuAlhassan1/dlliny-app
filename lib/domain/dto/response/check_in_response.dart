import 'package:json_annotation/json_annotation.dart';

part 'check_in_response.g.dart';

@JsonSerializable()
class CheckInResponse {
  final String checkInId;
  final String venueId;
  final String branchId;
  final String checkedInAt;
  final int distanceMeters;

  const CheckInResponse({
    required this.checkInId,
    required this.venueId,
    required this.branchId,
    required this.checkedInAt,
    required this.distanceMeters,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckInResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckInResponseToJson(this);
}
