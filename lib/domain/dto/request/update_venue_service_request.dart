import 'package:json_annotation/json_annotation.dart';

part 'update_venue_service_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateVenueServiceRequest {
  final double? price;
  final String? imageUrl;
  final bool? active;

  const UpdateVenueServiceRequest({
    this.price,
    this.imageUrl,
    this.active,
  });

  factory UpdateVenueServiceRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateVenueServiceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateVenueServiceRequestToJson(this);
}
