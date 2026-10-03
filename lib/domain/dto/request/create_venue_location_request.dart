import 'package:json_annotation/json_annotation.dart';

part 'create_venue_location_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateVenueLocationRequest {
  final String? labelAr;
  final String? labelEn;
  final String? addressAr;
  final String? addressEn;
  final int? cityId;
  final int? districtId;
  final String? phone;
  final double latitude;
  final double longitude;
  final bool? isPrimary;
  final int? sortOrder;

  const CreateVenueLocationRequest({
    this.labelAr,
    this.labelEn,
    this.addressAr,
    this.addressEn,
    this.cityId,
    this.districtId,
    this.phone,
    required this.latitude,
    required this.longitude,
    this.isPrimary,
    this.sortOrder,
  });

  factory CreateVenueLocationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateVenueLocationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateVenueLocationRequestToJson(this);
}
