import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'venue_response.g.dart';

@JsonSerializable()
class CityDto {
  final int id;
  final String nameAr;
  final String nameEn;

  const CityDto({required this.id, required this.nameAr, required this.nameEn});

  factory CityDto.fromJson(Map<String, dynamic> json) => _$CityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CityDtoToJson(this);
}

@JsonSerializable()
class DistrictDto {
  final int id;
  final String nameAr;
  final String nameEn;
  final int cityId;

  const DistrictDto({required this.id, required this.nameAr, required this.nameEn, required this.cityId});

  factory DistrictDto.fromJson(Map<String, dynamic> json) => _$DistrictDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DistrictDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CityWithDistrictsDto {
  final int id;
  final String nameAr;
  final String nameEn;
  final List<DistrictDto> districts;

  const CityWithDistrictsDto({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.districts,
  });

  factory CityWithDistrictsDto.fromJson(Map<String, dynamic> json) =>
      _$CityWithDistrictsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CityWithDistrictsDtoToJson(this);
}

@JsonSerializable()
class VenueCategoryDto {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String? icon;

  const VenueCategoryDto({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    this.icon,
  });

  factory VenueCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$VenueCategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueCategoryDtoToJson(this);
}

@JsonSerializable()
class VenueHoursDto {
  final String id;

  final int dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool closed;
  final bool ramadan;

  const VenueHoursDto({
    required this.id,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    required this.closed,
    required this.ramadan,
  });

  factory VenueHoursDto.fromJson(Map<String, dynamic> json) =>
      _$VenueHoursDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueHoursDtoToJson(this);
}

Object? _nameEnOrAr(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json['nameAr'];

@JsonSerializable(explicitToJson: true)
class VenueResponse {
  final String id;
  final String nameAr;

  @JsonKey(readValue: _nameEnOrAr, includeToJson: false)
  final String nameEn;

  @JsonKey(name: 'nameEn')
  final String? rawNameEn;

  final String? handle;

  final String? descriptionAr;
  final String? descriptionEn;
  final VenueCategoryDto? category;
  final double? latitude;
  final double? longitude;
  final String? addressAr;
  final String? addressEn;
  final int? cityId;
  final String? cityNameAr;
  final String? cityNameEn;
  final int? districtId;
  final String? districtNameAr;
  final String? districtNameEn;
  final String? phone;
  final String? website;

  @JsonKey(defaultValue: 0.0)
  final double avgRating;
  @JsonKey(defaultValue: 0)
  final int totalRatings;
  @JsonKey(defaultValue: 0)
  final int followerCount;
  final bool verified;
  final bool family;
  final bool hasShisha;
  final bool hasParking;
  final bool hasWifi;
  final bool hasOutdoor;
  final bool hasPrivateRoom;
  final List<VenueHoursDto> hours;
  final List<String> mediaUrls;

  final String? logoUrl;

  final String? coverUrl;

  final String? coverMediaType;

  final String? coverThumbnailUrl;

  final String? coverStreamUrl;

  @JsonKey(defaultValue: false)
  final bool isFollowing;

  @JsonKey(defaultValue: 0)
  final int postsCount;

  @JsonKey(defaultValue: 0)
  final int hangoutsCount;

  final String? viewerRole;

  @JsonKey(defaultValue: <VenueLocationResponse>[])
  final List<VenueLocationResponse> locations;

  @JsonKey(defaultValue: false)
  final bool onlineOnly;

  final VenueOpeningHoursDto? openingHours;

  final VenueGalleryDto? gallery;

  const VenueResponse({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.rawNameEn,
    this.handle,
    this.descriptionAr,
    this.descriptionEn,
    this.category,
    this.latitude,
    this.longitude,
    this.addressAr,
    this.addressEn,
    this.cityId,
    this.cityNameAr,
    this.cityNameEn,
    this.districtId,
    this.districtNameAr,
    this.districtNameEn,
    this.phone,
    this.website,
    required this.avgRating,
    required this.totalRatings,
    required this.followerCount,
    required this.verified,
    required this.family,
    required this.hasShisha,
    required this.hasParking,
    required this.hasWifi,
    required this.hasOutdoor,
    required this.hasPrivateRoom,
    required this.hours,
    required this.mediaUrls,
    this.logoUrl,
    this.coverUrl,
    this.coverMediaType,
    this.coverThumbnailUrl,
    this.coverStreamUrl,
    this.isFollowing = false,
    this.postsCount = 0,
    this.hangoutsCount = 0,
    this.viewerRole,
    this.locations = const [],
    this.onlineOnly = false,
    this.openingHours,
    this.gallery,
  });

  factory VenueResponse.fromJson(Map<String, dynamic> json) =>
      _$VenueResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VenueResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VenueSummaryResponse {
  final String id;
  final String nameAr;
  final String nameEn;

  final String? handle;

  final int? cityId;
  final String? cityNameAr;
  final int? districtId;
  final String? districtNameAr;
  final VenueCategoryDto? category;
  @JsonKey(defaultValue: 0.0)
  final double avgRating;
  @JsonKey(defaultValue: 0)
  final int totalRatings;
  final bool verified;
  final bool hasShisha;
  final bool hasParking;
  final String? logoUrl;
  final String? coverUrl;

  final String? coverStreamUrl;

  final double? latitude;
  final double? longitude;
  final double? distanceMeters;

  @JsonKey(defaultValue: false)
  final bool onlineOnly;

  @JsonKey(defaultValue: false)
  final bool isFollowing;

  @JsonKey(defaultValue: 0)
  final int followersCount;

  const VenueSummaryResponse({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.handle,
    this.cityId,
    this.cityNameAr,
    this.districtId,
    this.districtNameAr,
    this.category,
    required this.avgRating,
    required this.totalRatings,
    required this.verified,
    required this.hasShisha,
    required this.hasParking,
    this.logoUrl,
    this.coverUrl,
    this.coverStreamUrl,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.isFollowing = false,
    this.followersCount = 0,
    this.onlineOnly = false,
  });

  factory VenueSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$VenueSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VenueSummaryResponseToJson(this);
}

@JsonSerializable()
class MapVenuePinResponse {
  final String id;

  final String? locationId;

  final String nameAr;
  final String nameEn;

  final String? labelAr;
  final String? labelEn;

  final double latitude;
  final double longitude;
  final String? categoryCode;
  @JsonKey(defaultValue: 0.0)
  final double avgRating;
  final bool hasActiveHangout;

  final String? logoUrl;

  const MapVenuePinResponse({
    required this.id,
    this.locationId,
    required this.nameAr,
    required this.nameEn,
    this.labelAr,
    this.labelEn,
    required this.latitude,
    required this.longitude,
    this.categoryCode,
    required this.avgRating,
    required this.hasActiveHangout,
    this.logoUrl,
  });

  factory MapVenuePinResponse.fromJson(Map<String, dynamic> json) =>
      _$MapVenuePinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MapVenuePinResponseToJson(this);
}
