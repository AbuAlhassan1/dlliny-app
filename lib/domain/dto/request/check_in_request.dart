import 'package:json_annotation/json_annotation.dart';

part 'check_in_request.g.dart';

@JsonSerializable()
class CheckInRequest {
  final double latitude;
  final double longitude;

  const CheckInRequest({required this.latitude, required this.longitude});

  factory CheckInRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckInRequestToJson(this);
}
