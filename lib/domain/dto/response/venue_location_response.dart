import 'package:json_annotation/json_annotation.dart';

part 'venue_location_response.g.dart';

@JsonSerializable()
class VenueLocationResponse {
  final String id;
  final String venueId;

  final String? labelAr;
  final String? labelEn;

  final String? addressAr;
  final String? addressEn;

  final int? cityId;
  final String? cityNameAr;
  final int? districtId;
  final String? districtNameAr;
  final String? districtNameEn;

  final String? phone;

  final double latitude;
  final double longitude;

  final bool isPrimary;
  final int sortOrder;

  const VenueLocationResponse({
    required this.id,
    required this.venueId,
    this.labelAr,
    this.labelEn,
    this.addressAr,
    this.addressEn,
    this.cityId,
    this.cityNameAr,
    this.districtId,
    this.districtNameAr,
    this.districtNameEn,
    this.phone,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory VenueLocationResponse.fromJson(Map<String, dynamic> json) =>
      _$VenueLocationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VenueLocationResponseToJson(this);
}
