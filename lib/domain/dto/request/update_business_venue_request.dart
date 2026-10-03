import 'package:json_annotation/json_annotation.dart';

part 'update_business_venue_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateBusinessVenueRequest {
  final String? nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final int? categoryId;
  final double? latitude;
  final double? longitude;
  final String? addressAr;
  final String? addressEn;
  final int? cityId;
  final int? districtId;
  final String? phone;
  final String? website;

  final int? priceRange;

  final bool? inheritStyle;
  final String? style;

  final bool? onlineOnly;

  final bool? force;

  const UpdateBusinessVenueRequest({
    this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.categoryId,
    this.latitude,
    this.longitude,
    this.addressAr,
    this.addressEn,
    this.cityId,
    this.districtId,
    this.phone,
    this.website,
    this.priceRange,
    this.inheritStyle,
    this.style,
    this.onlineOnly,
    this.force,
  });

  factory UpdateBusinessVenueRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateBusinessVenueRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateBusinessVenueRequestToJson(this);
}
