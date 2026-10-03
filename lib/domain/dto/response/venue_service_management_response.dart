import 'package:json_annotation/json_annotation.dart';

part 'venue_service_management_response.g.dart';

@JsonSerializable()
class VenueServiceResponse {
  final String id;
  final int serviceTypeId;
  final String serviceTypeCode;
  final String serviceTypeNameAr;
  final String serviceTypeNameEn;

  final String category;

  final double? price;

  final String? imageUrl;

  final bool active;

  const VenueServiceResponse({
    required this.id,
    required this.serviceTypeId,
    required this.serviceTypeCode,
    required this.serviceTypeNameAr,
    required this.serviceTypeNameEn,
    required this.category,
    this.price,
    this.imageUrl,
    required this.active,
  });

  factory VenueServiceResponse.fromJson(Map<String, dynamic> json) =>
      _$VenueServiceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VenueServiceResponseToJson(this);
}

@JsonSerializable()
class ServiceImageUploadResponse {
  final String uploadUrl;
  final String key;

  const ServiceImageUploadResponse({
    required this.uploadUrl,
    required this.key,
  });

  factory ServiceImageUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$ServiceImageUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceImageUploadResponseToJson(this);
}
