import 'package:json_annotation/json_annotation.dart';

part 'update_venue_handle_request.g.dart';

@JsonSerializable()
class UpdateVenueHandleRequest {
  final String handle;

  const UpdateVenueHandleRequest({required this.handle});

  factory UpdateVenueHandleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateVenueHandleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateVenueHandleRequestToJson(this);
}
