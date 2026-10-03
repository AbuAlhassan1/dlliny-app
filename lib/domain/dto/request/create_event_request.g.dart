// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_event_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateEventRequest _$CreateEventRequestFromJson(Map<String, dynamic> json) =>
    CreateEventRequest(
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String,
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      startsAt: json['startsAt'] as String,
      endsAt: json['endsAt'] as String?,
      externalUrl: json['externalUrl'] as String?,
      externalUrlLabel: json['externalUrlLabel'] as String?,
      venueId: json['venueId'] as String?,
      venueLocationId: json['venueLocationId'] as String?,
      hangoutId: json['hangoutId'] as String?,
    );

Map<String, dynamic> _$CreateEventRequestToJson(CreateEventRequest instance) =>
    <String, dynamic>{
      'titleAr': instance.titleAr,
      'titleEn': instance.titleEn,
      'descriptionAr': ?instance.descriptionAr,
      'descriptionEn': ?instance.descriptionEn,
      'startsAt': instance.startsAt,
      'endsAt': ?instance.endsAt,
      'externalUrl': ?instance.externalUrl,
      'externalUrlLabel': ?instance.externalUrlLabel,
      'venueId': ?instance.venueId,
      'venueLocationId': ?instance.venueLocationId,
      'hangoutId': ?instance.hangoutId,
    };
