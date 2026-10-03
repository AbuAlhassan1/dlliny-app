import 'package:json_annotation/json_annotation.dart';

part 'search_response.g.dart';

@JsonSerializable(explicitToJson: true)
class VenueSearchResultDto {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? city;
  final String? district;
  final String? categoryCode;

  final String? logoUrl;

  final double? avgRating;
  final bool verified;

  @JsonKey(defaultValue: false)
  final bool onlineOnly;

  final LocationSummaryDto? location;

  const VenueSearchResultDto({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.city,
    this.district,
    this.categoryCode,
    this.logoUrl,
    required this.avgRating,
    required this.verified,
    this.onlineOnly = false,
    this.location,
  });

  factory VenueSearchResultDto.fromJson(Map<String, dynamic> json) =>
      _$VenueSearchResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueSearchResultDtoToJson(this);
}

@JsonSerializable()
class LocationSummaryDto {
  final double? latitude;
  final double? longitude;
  final String? cityNameAr;
  final String? cityNameEn;
  final String? districtNameAr;
  final String? districtNameEn;

  const LocationSummaryDto({
    this.latitude,
    this.longitude,
    this.cityNameAr,
    this.cityNameEn,
    this.districtNameAr,
    this.districtNameEn,
  });

  factory LocationSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$LocationSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationSummaryDtoToJson(this);
}

@JsonSerializable()
class UserSearchResultDto {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool verified;

  const UserSearchResultDto({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.verified,
  });

  factory UserSearchResultDto.fromJson(Map<String, dynamic> json) =>
      _$UserSearchResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserSearchResultDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SearchResultResponse {
  final List<VenueSearchResultDto> venues;
  final List<UserSearchResultDto> users;

  const SearchResultResponse({required this.venues, required this.users});

  factory SearchResultResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResultResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultResponseToJson(this);
}
