// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VenueSearchResultDto _$VenueSearchResultDtoFromJson(
  Map<String, dynamic> json,
) => VenueSearchResultDto(
  id: json['id'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  city: json['city'] as String?,
  district: json['district'] as String?,
  categoryCode: json['categoryCode'] as String?,
  logoUrl: json['logoUrl'] as String?,
  avgRating: (json['avgRating'] as num?)?.toDouble(),
  verified: json['verified'] as bool,
  onlineOnly: json['onlineOnly'] as bool? ?? false,
  location: json['location'] == null
      ? null
      : LocationSummaryDto.fromJson(json['location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VenueSearchResultDtoToJson(
  VenueSearchResultDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'city': instance.city,
  'district': instance.district,
  'categoryCode': instance.categoryCode,
  'logoUrl': instance.logoUrl,
  'avgRating': instance.avgRating,
  'verified': instance.verified,
  'onlineOnly': instance.onlineOnly,
  'location': instance.location?.toJson(),
};

LocationSummaryDto _$LocationSummaryDtoFromJson(Map<String, dynamic> json) =>
    LocationSummaryDto(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cityNameAr: json['cityNameAr'] as String?,
      cityNameEn: json['cityNameEn'] as String?,
      districtNameAr: json['districtNameAr'] as String?,
      districtNameEn: json['districtNameEn'] as String?,
    );

Map<String, dynamic> _$LocationSummaryDtoToJson(LocationSummaryDto instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'cityNameAr': instance.cityNameAr,
      'cityNameEn': instance.cityNameEn,
      'districtNameAr': instance.districtNameAr,
      'districtNameEn': instance.districtNameEn,
    };

UserSearchResultDto _$UserSearchResultDtoFromJson(Map<String, dynamic> json) =>
    UserSearchResultDto(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      verified: json['verified'] as bool,
    );

Map<String, dynamic> _$UserSearchResultDtoToJson(
  UserSearchResultDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'verified': instance.verified,
};

SearchResultResponse _$SearchResultResponseFromJson(
  Map<String, dynamic> json,
) => SearchResultResponse(
  venues: (json['venues'] as List<dynamic>)
      .map((e) => VenueSearchResultDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  users: (json['users'] as List<dynamic>)
      .map((e) => UserSearchResultDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SearchResultResponseToJson(
  SearchResultResponse instance,
) => <String, dynamic>{
  'venues': instance.venues.map((e) => e.toJson()).toList(),
  'users': instance.users.map((e) => e.toJson()).toList(),
};
