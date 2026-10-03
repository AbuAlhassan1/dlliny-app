// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_venue_review_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingVenueReviewResponse _$PendingVenueReviewResponseFromJson(
  Map<String, dynamic> json,
) => PendingVenueReviewResponse(
  hangoutId: json['hangoutId'] as String,
  scheduledAt: json['scheduledAt'] as String,
  hangoutDescription: json['hangoutDescription'] as String?,
  attendedAs: json['attendedAs'] as String,
  venueId: json['venueId'] as String,
  venueNameAr: json['venueNameAr'] as String,
  venueNameEn: json['venueNameEn'] as String,
  venueLogoUrl: json['venueLogoUrl'] as String?,
  attendees:
      (json['attendees'] as List<dynamic>?)
          ?.map((e) => HangoutAttendee.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PendingVenueReviewResponseToJson(
  PendingVenueReviewResponse instance,
) => <String, dynamic>{
  'hangoutId': instance.hangoutId,
  'scheduledAt': instance.scheduledAt,
  'hangoutDescription': instance.hangoutDescription,
  'attendedAs': instance.attendedAs,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'venueLogoUrl': instance.venueLogoUrl,
  'attendees': instance.attendees,
};
