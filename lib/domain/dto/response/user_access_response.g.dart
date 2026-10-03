// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_access_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAccessResponse _$UserAccessResponseFromJson(Map<String, dynamic> json) =>
    UserAccessResponse(
      businesses:
          (json['businesses'] as List<dynamic>?)
              ?.map((e) => BusinessAccess.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      orphanVenues:
          (json['orphanVenues'] as List<dynamic>?)
              ?.map((e) => VenueAccess.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$UserAccessResponseToJson(UserAccessResponse instance) =>
    <String, dynamic>{
      'businesses': instance.businesses.map((e) => e.toJson()).toList(),
      'orphanVenues': instance.orphanVenues.map((e) => e.toJson()).toList(),
    };

BusinessAccess _$BusinessAccessFromJson(Map<String, dynamic> json) =>
    BusinessAccess(
      businessId: json['businessId'] as String,
      companyName: json['companyName'] as String?,
      active: json['active'] as bool,
      verified: json['verified'] as bool,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      businessRoleName: json['businessRoleName'] as String?,
      businessPermissions:
          (json['businessPermissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      venues:
          (json['venues'] as List<dynamic>?)
              ?.map((e) => VenueAccess.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$BusinessAccessToJson(BusinessAccess instance) =>
    <String, dynamic>{
      'businessId': instance.businessId,
      'companyName': instance.companyName,
      'active': instance.active,
      'verified': instance.verified,
      'createdAt': instance.createdAt?.toIso8601String(),
      'businessRoleName': instance.businessRoleName,
      'businessPermissions': instance.businessPermissions,
      'venues': instance.venues.map((e) => e.toJson()).toList(),
    };

VenueAccess _$VenueAccessFromJson(Map<String, dynamic> json) => VenueAccess(
  venueId: json['venueId'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String?,
  logoUrl: json['logoUrl'] as String?,
  active: json['active'] as bool,
  verified: json['verified'] as bool,
  venueRoleName: json['venueRoleName'] as String?,
  venuePermissions:
      (json['venuePermissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  effectivePermissions:
      (json['effectivePermissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$VenueAccessToJson(VenueAccess instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'logoUrl': instance.logoUrl,
      'active': instance.active,
      'verified': instance.verified,
      'venueRoleName': instance.venueRoleName,
      'venuePermissions': instance.venuePermissions,
      'effectivePermissions': instance.effectivePermissions,
    };
