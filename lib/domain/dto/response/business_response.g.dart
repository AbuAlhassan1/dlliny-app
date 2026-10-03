// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessAccountResponse _$BusinessAccountResponseFromJson(
  Map<String, dynamic> json,
) => BusinessAccountResponse(
  id: json['id'] as String,
  ownerName: json['ownerName'] as String,
  companyName: json['companyName'] as String?,
  active: json['active'] as bool,
  verified: json['verified'] as bool,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$BusinessAccountResponseToJson(
  BusinessAccountResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'ownerName': instance.ownerName,
  'companyName': instance.companyName,
  'active': instance.active,
  'verified': instance.verified,
  'createdAt': instance.createdAt,
};

SubscriptionTierResponse _$SubscriptionTierResponseFromJson(
  Map<String, dynamic> json,
) => SubscriptionTierResponse(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  billingPeriod: json['billingPeriod'] as String,
  featuredPerks:
      (json['featuredPerks'] as List<dynamic>?)
          ?.map((e) => FeaturedPerkResponse.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$SubscriptionTierResponseToJson(
  SubscriptionTierResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'billingPeriod': instance.billingPeriod,
  'featuredPerks': instance.featuredPerks.map((e) => e.toJson()).toList(),
  'permissions': instance.permissions,
};

MySubscriptionResponse _$MySubscriptionResponseFromJson(
  Map<String, dynamic> json,
) => MySubscriptionResponse(
  id: json['id'] as String,
  tierId: json['tierId'] as String,
  tierName: json['tierName'] as String,
  status: json['status'] as String,
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  startedAt: json['startedAt'] as String,
  expiresAt: json['expiresAt'] as String,
  primary: json['primary'] as bool? ?? false,
);

Map<String, dynamic> _$MySubscriptionResponseToJson(
  MySubscriptionResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'tierId': instance.tierId,
  'tierName': instance.tierName,
  'status': instance.status,
  'permissions': instance.permissions,
  'startedAt': instance.startedAt,
  'expiresAt': instance.expiresAt,
  'primary': instance.primary,
};

BusinessVenueResponse _$BusinessVenueResponseFromJson(
  Map<String, dynamic> json,
) => BusinessVenueResponse(
  venueId: json['venueId'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  handle: json['handle'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  cityNameAr: json['cityNameAr'] as String?,
  districtId: (json['districtId'] as num?)?.toInt(),
  districtNameAr: json['districtNameAr'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  addressAr: json['addressAr'] as String?,
  addressEn: json['addressEn'] as String?,
  phone: json['phone'] as String?,
  avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
  totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
  verified: json['verified'] as bool,
  active: json['active'] as bool,
  inheritStyle: json['inheritStyle'] as bool,
  style: json['style'] as String?,
  effectiveStyle: json['effectiveStyle'] as String?,
  logoUrl: json['logoUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  coverMediaType: json['coverMediaType'] as String?,
  coverStreamUrl: json['coverStreamUrl'] as String?,
  onlineOnly: json['onlineOnly'] as bool? ?? false,
);

Map<String, dynamic> _$BusinessVenueResponseToJson(
  BusinessVenueResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'handle': instance.handle,
  'cityId': instance.cityId,
  'cityNameAr': instance.cityNameAr,
  'districtId': instance.districtId,
  'districtNameAr': instance.districtNameAr,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'addressAr': instance.addressAr,
  'addressEn': instance.addressEn,
  'phone': instance.phone,
  'avgRating': instance.avgRating,
  'totalRatings': instance.totalRatings,
  'verified': instance.verified,
  'active': instance.active,
  'inheritStyle': instance.inheritStyle,
  'style': instance.style,
  'effectiveStyle': instance.effectiveStyle,
  'logoUrl': instance.logoUrl,
  'coverUrl': instance.coverUrl,
  'coverMediaType': instance.coverMediaType,
  'coverStreamUrl': instance.coverStreamUrl,
  'onlineOnly': instance.onlineOnly,
};

VenueMediaUploadResponse _$VenueMediaUploadResponseFromJson(
  Map<String, dynamic> json,
) => VenueMediaUploadResponse(
  uploadUrl: json['uploadUrl'] as String,
  key: json['key'] as String,
);

Map<String, dynamic> _$VenueMediaUploadResponseToJson(
  VenueMediaUploadResponse instance,
) => <String, dynamic>{'uploadUrl': instance.uploadUrl, 'key': instance.key};

VerificationRequestResponse _$VerificationRequestResponseFromJson(
  Map<String, dynamic> json,
) => VerificationRequestResponse(
  id: json['id'] as String,
  venueId: json['venueId'] as String,
  venueNameAr: json['venueNameAr'] as String,
  venueNameEn: json['venueNameEn'] as String,
  status: json['status'] as String,
  reviewerNotes: json['reviewerNotes'] as String?,
  submittedAt: json['submittedAt'] as String,
  reviewedAt: json['reviewedAt'] as String?,
);

Map<String, dynamic> _$VerificationRequestResponseToJson(
  VerificationRequestResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'status': instance.status,
  'reviewerNotes': instance.reviewerNotes,
  'submittedAt': instance.submittedAt,
  'reviewedAt': instance.reviewedAt,
};

CampaignCreativeResponse _$CampaignCreativeResponseFromJson(
  Map<String, dynamic> json,
) => CampaignCreativeResponse(
  id: json['id'] as String,
  sourceType: json['sourceType'] as String,
  sourcePostId: json['sourcePostId'] as String?,
  sourceHangoutId: json['sourceHangoutId'] as String?,
  mediaUrl: json['mediaUrl'] as String?,
  mediaType: json['mediaType'] as String?,
  mediaStreamUrl: json['mediaStreamUrl'] as String?,
  caption: json['caption'] as String?,
  sourceCaption: json['sourceCaption'] as String?,
  ctaText: json['ctaText'] as String?,
  ctaUrl: json['ctaUrl'] as String?,
);

Map<String, dynamic> _$CampaignCreativeResponseToJson(
  CampaignCreativeResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'sourceType': instance.sourceType,
  'sourcePostId': instance.sourcePostId,
  'sourceHangoutId': instance.sourceHangoutId,
  'mediaUrl': instance.mediaUrl,
  'mediaType': instance.mediaType,
  'mediaStreamUrl': instance.mediaStreamUrl,
  'caption': instance.caption,
  'sourceCaption': instance.sourceCaption,
  'ctaText': instance.ctaText,
  'ctaUrl': instance.ctaUrl,
};

CampaignResponse _$CampaignResponseFromJson(Map<String, dynamic> json) =>
    CampaignResponse(
      id: json['id'] as String,
      venueId: json['venueId'] as String,
      venueName: json['venueName'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      budget: (json['budget'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      clickCount: (json['clickCount'] as num).toInt(),
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      targetDistricts:
          (json['targetDistricts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      targetCategories:
          (json['targetCategories'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      startsAt: json['startsAt'] as String? ?? '',
      endsAt: json['endsAt'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      creative: json['creative'] == null
          ? null
          : CampaignCreativeResponse.fromJson(
              json['creative'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CampaignResponseToJson(CampaignResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'venueId': instance.venueId,
      'venueName': instance.venueName,
      'name': instance.name,
      'type': instance.type,
      'budget': instance.budget,
      'spent': instance.spent,
      'clickCount': instance.clickCount,
      'status': instance.status,
      'rejectionReason': instance.rejectionReason,
      'targetDistricts': instance.targetDistricts,
      'targetCategories': instance.targetCategories,
      'startsAt': instance.startsAt,
      'endsAt': instance.endsAt,
      'createdAt': instance.createdAt,
      'creative': instance.creative?.toJson(),
    };

BusinessRequestResponse _$BusinessRequestResponseFromJson(
  Map<String, dynamic> json,
) => BusinessRequestResponse(
  id: json['id'] as String,
  companyName: json['companyName'] as String?,
  description: json['description'] as String?,
  status: json['status'] as String,
  reviewerNotes: json['reviewerNotes'] as String?,
  submittedAt: json['submittedAt'] as String,
  reviewedAt: json['reviewedAt'] as String?,
);

Map<String, dynamic> _$BusinessRequestResponseToJson(
  BusinessRequestResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'companyName': instance.companyName,
  'description': instance.description,
  'status': instance.status,
  'reviewerNotes': instance.reviewerNotes,
  'submittedAt': instance.submittedAt,
  'reviewedAt': instance.reviewedAt,
};
