// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'served_ad_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServedAdItem _$ServedAdItemFromJson(Map<String, dynamic> json) => ServedAdItem(
  adId: json['adId'] as String,
  placement: json['placement'] as String,
  venueId: json['venueId'] as String?,
  venueNameAr: json['venueNameAr'] as String?,
  venueNameEn: json['venueNameEn'] as String?,
  venueLogoUrl: json['venueLogoUrl'] as String?,
  sourceType: json['sourceType'] as String?,
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

Map<String, dynamic> _$ServedAdItemToJson(ServedAdItem instance) =>
    <String, dynamic>{
      'adId': instance.adId,
      'placement': instance.placement,
      'venueId': instance.venueId,
      'venueNameAr': instance.venueNameAr,
      'venueNameEn': instance.venueNameEn,
      'venueLogoUrl': instance.venueLogoUrl,
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

ServedAdResponse _$ServedAdResponseFromJson(Map<String, dynamic> json) =>
    ServedAdResponse(
      placement: json['placement'] as String,
      ads: (json['ads'] as List<dynamic>)
          .map((e) => ServedAdItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServedAdResponseToJson(ServedAdResponse instance) =>
    <String, dynamic>{
      'placement': instance.placement,
      'ads': instance.ads.map((e) => e.toJson()).toList(),
    };
