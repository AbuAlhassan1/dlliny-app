import 'package:json_annotation/json_annotation.dart';

import 'featured_perk_response.dart';

part 'business_response.g.dart';

@JsonSerializable()
class BusinessAccountResponse {
  final String id;
  final String ownerName;
  final String? companyName;
  final bool active;
  final bool verified;
  final String createdAt;

  const BusinessAccountResponse({
    required this.id,
    required this.ownerName,
    this.companyName,
    required this.active,
    required this.verified,
    required this.createdAt,
  });

  factory BusinessAccountResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessAccountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessAccountResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SubscriptionTierResponse {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String billingPeriod;

  @JsonKey(defaultValue: [])
  final List<FeaturedPerkResponse> featuredPerks;

  @JsonKey(defaultValue: [])
  final List<String> permissions;

  const SubscriptionTierResponse({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.billingPeriod,
    this.featuredPerks = const [],
    this.permissions = const [],
  });

  factory SubscriptionTierResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionTierResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionTierResponseToJson(this);
}

@JsonSerializable()
class MySubscriptionResponse {
  final String id;
  final String tierId;
  final String tierName;
  final String status;

  @JsonKey(defaultValue: <String>[])
  final List<String> permissions;

  final String startedAt;
  final String expiresAt;

  @JsonKey(defaultValue: false)
  final bool primary;

  const MySubscriptionResponse({
    required this.id,
    required this.tierId,
    required this.tierName,
    required this.status,
    this.permissions = const [],
    required this.startedAt,
    required this.expiresAt,
    this.primary = false,
  });

  factory MySubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$MySubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MySubscriptionResponseToJson(this);
}

@JsonSerializable()
class BusinessVenueResponse {
  final String venueId;
  final String nameAr;
  final String nameEn;

  final String? handle;

  final int? cityId;
  final String? cityNameAr;
  final int? districtId;
  final String? districtNameAr;

  final double? latitude;
  final double? longitude;

  final String? addressAr;
  final String? addressEn;
  final String? phone;

  @JsonKey(defaultValue: 0.0)
  final double avgRating;
  @JsonKey(defaultValue: 0)
  final int totalRatings;
  final bool verified;
  final bool active;
  final bool inheritStyle;
  final String? style;
  final String? effectiveStyle;

  final String? logoUrl;

  final String? coverUrl;

  final String? coverMediaType;

  final String? coverStreamUrl;

  @JsonKey(defaultValue: false)
  final bool onlineOnly;

  const BusinessVenueResponse({
    required this.venueId,
    required this.nameAr,
    required this.nameEn,
    this.handle,
    this.cityId,
    this.cityNameAr,
    this.districtId,
    this.districtNameAr,
    this.latitude,
    this.longitude,
    this.addressAr,
    this.addressEn,
    this.phone,
    required this.avgRating,
    required this.totalRatings,
    required this.verified,
    required this.active,
    required this.inheritStyle,
    this.style,
    this.effectiveStyle,
    this.logoUrl,
    this.coverUrl,
    this.coverMediaType,
    this.coverStreamUrl,
    this.onlineOnly = false,
  });

  factory BusinessVenueResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessVenueResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessVenueResponseToJson(this);
}

@JsonSerializable()
class VenueMediaUploadResponse {
  final String uploadUrl;
  final String key;

  const VenueMediaUploadResponse({required this.uploadUrl, required this.key});

  factory VenueMediaUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$VenueMediaUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VenueMediaUploadResponseToJson(this);
}

@JsonSerializable()
class VerificationRequestResponse {
  final String id;
  final String venueId;
  final String venueNameAr;
  final String venueNameEn;
  final String status;
  final String? reviewerNotes;
  final String submittedAt;
  final String? reviewedAt;

  const VerificationRequestResponse({
    required this.id,
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    required this.status,
    this.reviewerNotes,
    required this.submittedAt,
    this.reviewedAt,
  });

  factory VerificationRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequestResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationRequestResponseToJson(this);
}

@JsonSerializable()
class CampaignCreativeResponse {
  final String id;

  final String sourceType;

  final String? sourcePostId;

  final String? sourceHangoutId;

  final String? mediaUrl;

  final String? mediaType;

  final String? mediaStreamUrl;

  final String? caption;

  final String? sourceCaption;

  final String? ctaText;

  final String? ctaUrl;

  const CampaignCreativeResponse({
    required this.id,
    required this.sourceType,
    this.sourcePostId,
    this.sourceHangoutId,
    this.mediaUrl,
    this.mediaType,
    this.mediaStreamUrl,
    this.caption,
    this.sourceCaption,
    this.ctaText,
    this.ctaUrl,
  });

  factory CampaignCreativeResponse.fromJson(Map<String, dynamic> json) =>
      _$CampaignCreativeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignCreativeResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CampaignResponse {
  final String id;
  final String venueId;
  final String? venueName;
  final String name;
  final String type;
  final double budget;
  final double spent;

  final int clickCount;

  final String status;
  final String? rejectionReason;

  @JsonKey(defaultValue: <String>[])
  final List<String> targetDistricts;
  @JsonKey(defaultValue: <int>[])
  final List<int> targetCategories;

  @JsonKey(defaultValue: '')
  final String startsAt;
  @JsonKey(defaultValue: '')
  final String endsAt;
  @JsonKey(defaultValue: '')
  final String createdAt;

  final CampaignCreativeResponse? creative;

  const CampaignResponse({
    required this.id,
    required this.venueId,
    this.venueName,
    required this.name,
    required this.type,
    required this.budget,
    required this.spent,
    required this.clickCount,
    required this.status,
    this.rejectionReason,
    required this.targetDistricts,
    required this.targetCategories,
    required this.startsAt,
    required this.endsAt,
    required this.createdAt,
    this.creative,
  });

  factory CampaignResponse.fromJson(Map<String, dynamic> json) =>
      _$CampaignResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignResponseToJson(this);
}

@JsonSerializable()
class BusinessRequestResponse {
  final String id;
  final String? companyName;
  final String? description;
  final String status;
  final String? reviewerNotes;
  final String submittedAt;
  final String? reviewedAt;

  const BusinessRequestResponse({
    required this.id,
    this.companyName,
    this.description,
    required this.status,
    this.reviewerNotes,
    required this.submittedAt,
    this.reviewedAt,
  });

  factory BusinessRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessRequestResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessRequestResponseToJson(this);
}
