// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewResponse _$ReviewResponseFromJson(Map<String, dynamic> json) =>
    ReviewResponse(
      id: json['id'] as String,
      venueId: json['venueId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      ratingOverall: (json['ratingOverall'] as num).toInt(),
      ratingAtmosphere: (json['ratingAtmosphere'] as num?)?.toInt(),
      ratingService: (json['ratingService'] as num?)?.toInt(),
      ratingValue: (json['ratingValue'] as num?)?.toInt(),
      body: json['body'] as String?,
      businessReply: json['businessReply'] as String?,
      repliedAt: json['repliedAt'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$ReviewResponseToJson(ReviewResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'venueId': instance.venueId,
      'userId': instance.userId,
      'username': instance.username,
      'userAvatarUrl': instance.userAvatarUrl,
      'ratingOverall': instance.ratingOverall,
      'ratingAtmosphere': instance.ratingAtmosphere,
      'ratingService': instance.ratingService,
      'ratingValue': instance.ratingValue,
      'body': instance.body,
      'businessReply': instance.businessReply,
      'repliedAt': instance.repliedAt,
      'createdAt': instance.createdAt,
    };
