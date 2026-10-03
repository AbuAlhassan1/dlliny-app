import 'package:json_annotation/json_annotation.dart';

part 'update_venue_location_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateVenueLocationRequest {
  final String? labelAr;
  final String? labelEn;
  final String? addressAr;
  final String? addressEn;
  final int? cityId;
  final int? districtId;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool? isPrimary;
  final int? sortOrder;

  const UpdateVenueLocationRequest({
    this.labelAr,
    this.labelEn,
    this.addressAr,
    this.addressEn,
    this.cityId,
    this.districtId,
    this.phone,
    this.latitude,
    this.longitude,
    this.isPrimary,
    this.sortOrder,
  });

  factory UpdateVenueLocationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateVenueLocationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateVenueLocationRequestToJson(this);
}
