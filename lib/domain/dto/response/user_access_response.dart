import 'package:json_annotation/json_annotation.dart';

part 'user_access_response.g.dart';

@JsonSerializable(explicitToJson: true)
class UserAccessResponse {
  @JsonKey(defaultValue: <BusinessAccess>[])
  final List<BusinessAccess> businesses;

  @JsonKey(defaultValue: <VenueAccess>[])
  final List<VenueAccess> orphanVenues;

  const UserAccessResponse({
    required this.businesses,
    required this.orphanVenues,
  });

  factory UserAccessResponse.fromJson(Map<String, dynamic> json) =>
      _$UserAccessResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserAccessResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BusinessAccess {
  final String businessId;
  final String? companyName;
  final bool active;
  final bool verified;
  final DateTime? createdAt;

  final String? businessRoleName;

  @JsonKey(defaultValue: <String>[])
  final List<String> businessPermissions;

  @JsonKey(defaultValue: <VenueAccess>[])
  final List<VenueAccess> venues;

  const BusinessAccess({
    required this.businessId,
    this.companyName,
    required this.active,
    required this.verified,
    this.createdAt,
    this.businessRoleName,
    required this.businessPermissions,
    required this.venues,
  });

  factory BusinessAccess.fromJson(Map<String, dynamic> json) =>
      _$BusinessAccessFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessAccessToJson(this);
}

@JsonSerializable()
class VenueAccess {
  final String venueId;
  final String nameAr;
  final String? nameEn;
  final String? logoUrl;
  final bool active;
  final bool verified;

  final String? venueRoleName;

  @JsonKey(defaultValue: <String>[])
  final List<String> venuePermissions;

  @JsonKey(defaultValue: <String>[])
  final List<String> effectivePermissions;

  const VenueAccess({
    required this.venueId,
    required this.nameAr,
    this.nameEn,
    this.logoUrl,
    required this.active,
    required this.verified,
    this.venueRoleName,
    required this.venuePermissions,
    required this.effectivePermissions,
  });

  factory VenueAccess.fromJson(Map<String, dynamic> json) =>
      _$VenueAccessFromJson(json);
  Map<String, dynamic> toJson() => _$VenueAccessToJson(this);
}
