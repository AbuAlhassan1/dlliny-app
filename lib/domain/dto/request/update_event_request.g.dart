// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_event_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateEventRequest _$UpdateEventRequestFromJson(Map<String, dynamic> json) =>
    UpdateEventRequest(
      titleAr: json['titleAr'] as String?,
      titleEn: json['titleEn'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      startsAt: json['startsAt'] as String?,
      endsAt: json['endsAt'] as String?,
      externalUrl: json['externalUrl'] as String?,
      externalUrlLabel: json['externalUrlLabel'] as String?,
      venueId: json['venueId'] as String?,
      venueLocationId: json['venueLocationId'] as String?,
      hangoutId: json['hangoutId'] as String?,
      active: json['active'] as bool?,
    );

Map<String, dynamic> _$UpdateEventRequestToJson(UpdateEventRequest instance) =>
    <String, dynamic>{
      'titleAr': ?instance.titleAr,
      'titleEn': ?instance.titleEn,
      'descriptionAr': ?instance.descriptionAr,
      'descriptionEn': ?instance.descriptionEn,
      'startsAt': ?instance.startsAt,
      'endsAt': ?instance.endsAt,
      'externalUrl': ?instance.externalUrl,
      'externalUrlLabel': ?instance.externalUrlLabel,
      'venueId': ?instance.venueId,
      'venueLocationId': ?instance.venueLocationId,
      'hangoutId': ?instance.hangoutId,
      'active': ?instance.active,
    };
