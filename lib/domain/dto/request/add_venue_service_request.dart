import 'package:json_annotation/json_annotation.dart';

part 'add_venue_service_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AddVenueServiceRequest {
  final int serviceTypeId;
  final double? price;
  final String? imageUrl;

  const AddVenueServiceRequest({
    required this.serviceTypeId,
    this.price,
    this.imageUrl,
  });

  factory AddVenueServiceRequest.fromJson(Map<String, dynamic> json) =>
      _$AddVenueServiceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddVenueServiceRequestToJson(this);
}
