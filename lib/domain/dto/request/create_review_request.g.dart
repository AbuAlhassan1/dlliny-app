// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_review_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateReviewRequest _$CreateReviewRequestFromJson(Map<String, dynamic> json) =>
    CreateReviewRequest(
      venueId: json['venueId'] as String,
      hangoutId: json['hangoutId'] as String?,
      ratingOverall: (json['ratingOverall'] as num).toInt(),
      ratingAtmosphere: (json['ratingAtmosphere'] as num?)?.toInt(),
      ratingService: (json['ratingService'] as num?)?.toInt(),
      ratingValue: (json['ratingValue'] as num?)?.toInt(),
      body: json['body'] as String?,
    );

Map<String, dynamic> _$CreateReviewRequestToJson(
  CreateReviewRequest instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'hangoutId': instance.hangoutId,
  'ratingOverall': instance.ratingOverall,
  'ratingAtmosphere': instance.ratingAtmosphere,
  'ratingService': instance.ratingService,
  'ratingValue': instance.ratingValue,
  'body': instance.body,
};
