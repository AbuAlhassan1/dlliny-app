import 'package:json_annotation/json_annotation.dart';

part 'create_business_venue_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateBusinessVenueRequest {
  final String nameAr;
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
  final bool inheritStyle;
  final String? style;

  final bool onlineOnly;

  final String? handle;

  const CreateBusinessVenueRequest({
    required this.nameAr,
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
    this.inheritStyle = true,
    this.style,
    this.onlineOnly = false,
    this.handle,
  });

  factory CreateBusinessVenueRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBusinessVenueRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBusinessVenueRequestToJson(this);
}
