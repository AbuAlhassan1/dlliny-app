// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CityDto _$CityDtoFromJson(Map<String, dynamic> json) => CityDto(
  id: (json['id'] as num).toInt(),
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
);

Map<String, dynamic> _$CityDtoToJson(CityDto instance) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
};

DistrictDto _$DistrictDtoFromJson(Map<String, dynamic> json) => DistrictDto(
  id: (json['id'] as num).toInt(),
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  cityId: (json['cityId'] as num).toInt(),
);

Map<String, dynamic> _$DistrictDtoToJson(DistrictDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'cityId': instance.cityId,
    };

CityWithDistrictsDto _$CityWithDistrictsDtoFromJson(
  Map<String, dynamic> json,
) => CityWithDistrictsDto(
  id: (json['id'] as num).toInt(),
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  districts: (json['districts'] as List<dynamic>)
      .map((e) => DistrictDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CityWithDistrictsDtoToJson(
  CityWithDistrictsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'districts': instance.districts.map((e) => e.toJson()).toList(),
};

VenueCategoryDto _$VenueCategoryDtoFromJson(Map<String, dynamic> json) =>
    VenueCategoryDto(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$VenueCategoryDtoToJson(VenueCategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'icon': instance.icon,
    };

VenueHoursDto _$VenueHoursDtoFromJson(Map<String, dynamic> json) =>
    VenueHoursDto(
      id: json['id'] as String,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      closed: json['closed'] as bool,
      ramadan: json['ramadan'] as bool,
    );

Map<String, dynamic> _$VenueHoursDtoToJson(VenueHoursDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dayOfWeek': instance.dayOfWeek,
      'openTime': instance.openTime,
      'closeTime': instance.closeTime,
      'closed': instance.closed,
      'ramadan': instance.ramadan,
    };

VenueResponse _$VenueResponseFromJson(Map<String, dynamic> json) =>
    VenueResponse(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: _nameEnOrAr(json, 'nameEn') as String,
      rawNameEn: json['nameEn'] as String?,
      handle: json['handle'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      category: json['category'] == null
          ? null
          : VenueCategoryDto.fromJson(json['category'] as Map<String, dynamic>),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      cityId: (json['cityId'] as num?)?.toInt(),
      cityNameAr: json['cityNameAr'] as String?,
      cityNameEn: json['cityNameEn'] as String?,
      districtId: (json['districtId'] as num?)?.toInt(),
      districtNameAr: json['districtNameAr'] as String?,
      districtNameEn: json['districtNameEn'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      verified: json['verified'] as bool,
      family: json['family'] as bool,
      hasShisha: json['hasShisha'] as bool,
      hasParking: json['hasParking'] as bool,
      hasWifi: json['hasWifi'] as bool,
      hasOutdoor: json['hasOutdoor'] as bool,
      hasPrivateRoom: json['hasPrivateRoom'] as bool,
      hours: (json['hours'] as List<dynamic>)
          .map((e) => VenueHoursDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaUrls: (json['mediaUrls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      logoUrl: json['logoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      coverMediaType: json['coverMediaType'] as String?,
      coverThumbnailUrl: json['coverThumbnailUrl'] as String?,
      coverStreamUrl: json['coverStreamUrl'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      hangoutsCount: (json['hangoutsCount'] as num?)?.toInt() ?? 0,
      viewerRole: json['viewerRole'] as String?,
      locations:
          (json['locations'] as List<dynamic>?)
              ?.map(
                (e) =>
                    VenueLocationResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      onlineOnly: json['onlineOnly'] as bool? ?? false,
      openingHours: json['openingHours'] == null
          ? null
          : VenueOpeningHoursDto.fromJson(
              json['openingHours'] as Map<String, dynamic>,
            ),
      gallery: json['gallery'] == null
          ? null
          : VenueGalleryDto.fromJson(json['gallery'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VenueResponseToJson(VenueResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'nameEn': instance.rawNameEn,
      'handle': instance.handle,
      'descriptionAr': instance.descriptionAr,
      'descriptionEn': instance.descriptionEn,
      'category': instance.category?.toJson(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'addressAr': instance.addressAr,
      'addressEn': instance.addressEn,
      'cityId': instance.cityId,
      'cityNameAr': instance.cityNameAr,
      'cityNameEn': instance.cityNameEn,
      'districtId': instance.districtId,
      'districtNameAr': instance.districtNameAr,
      'districtNameEn': instance.districtNameEn,
      'phone': instance.phone,
      'website': instance.website,
      'avgRating': instance.avgRating,
      'totalRatings': instance.totalRatings,
      'followerCount': instance.followerCount,
      'verified': instance.verified,
      'family': instance.family,
      'hasShisha': instance.hasShisha,
      'hasParking': instance.hasParking,
      'hasWifi': instance.hasWifi,
      'hasOutdoor': instance.hasOutdoor,
      'hasPrivateRoom': instance.hasPrivateRoom,
      'hours': instance.hours.map((e) => e.toJson()).toList(),
      'mediaUrls': instance.mediaUrls,
      'logoUrl': instance.logoUrl,
      'coverUrl': instance.coverUrl,
      'coverMediaType': instance.coverMediaType,
      'coverThumbnailUrl': instance.coverThumbnailUrl,
      'coverStreamUrl': instance.coverStreamUrl,
      'isFollowing': instance.isFollowing,
      'postsCount': instance.postsCount,
      'hangoutsCount': instance.hangoutsCount,
      'viewerRole': instance.viewerRole,
      'locations': instance.locations.map((e) => e.toJson()).toList(),
      'onlineOnly': instance.onlineOnly,
      'openingHours': instance.openingHours?.toJson(),
      'gallery': instance.gallery?.toJson(),
    };

VenueSummaryResponse _$VenueSummaryResponseFromJson(
  Map<String, dynamic> json,
) => VenueSummaryResponse(
  id: json['id'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  handle: json['handle'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  cityNameAr: json['cityNameAr'] as String?,
  districtId: (json['districtId'] as num?)?.toInt(),
  districtNameAr: json['districtNameAr'] as String?,
  category: json['category'] == null
      ? null
      : VenueCategoryDto.fromJson(json['category'] as Map<String, dynamic>),
  avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
  totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
  verified: json['verified'] as bool,
  hasShisha: json['hasShisha'] as bool,
  hasParking: json['hasParking'] as bool,
  logoUrl: json['logoUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  coverStreamUrl: json['coverStreamUrl'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
  isFollowing: json['isFollowing'] as bool? ?? false,
  followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
  onlineOnly: json['onlineOnly'] as bool? ?? false,
);

Map<String, dynamic> _$VenueSummaryResponseToJson(
  VenueSummaryResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'handle': instance.handle,
  'cityId': instance.cityId,
  'cityNameAr': instance.cityNameAr,
  'districtId': instance.districtId,
  'districtNameAr': instance.districtNameAr,
  'category': instance.category?.toJson(),
  'avgRating': instance.avgRating,
  'totalRatings': instance.totalRatings,
  'verified': instance.verified,
  'hasShisha': instance.hasShisha,
  'hasParking': instance.hasParking,
  'logoUrl': instance.logoUrl,
  'coverUrl': instance.coverUrl,
  'coverStreamUrl': instance.coverStreamUrl,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'distanceMeters': instance.distanceMeters,
  'onlineOnly': instance.onlineOnly,
  'isFollowing': instance.isFollowing,
  'followersCount': instance.followersCount,
};

MapVenuePinResponse _$MapVenuePinResponseFromJson(Map<String, dynamic> json) =>
    MapVenuePinResponse(
      id: json['id'] as String,
      locationId: json['locationId'] as String?,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      labelAr: json['labelAr'] as String?,
      labelEn: json['labelEn'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      categoryCode: json['categoryCode'] as String?,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      hasActiveHangout: json['hasActiveHangout'] as bool,
      logoUrl: json['logoUrl'] as String?,
    );

Map<String, dynamic> _$MapVenuePinResponseToJson(
  MapVenuePinResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'locationId': instance.locationId,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'labelAr': instance.labelAr,
  'labelEn': instance.labelEn,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'categoryCode': instance.categoryCode,
  'avgRating': instance.avgRating,
  'hasActiveHangout': instance.hasActiveHangout,
  'logoUrl': instance.logoUrl,
};
