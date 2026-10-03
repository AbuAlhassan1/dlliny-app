// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_points_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPointsResponse _$UserPointsResponseFromJson(Map<String, dynamic> json) =>
    UserPointsResponse(
      totalPoints: (json['totalPoints'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      currentLevelThreshold: (json['currentLevelThreshold'] as num).toInt(),
      nextLevelThreshold: (json['nextLevelThreshold'] as num?)?.toInt(),
      pointsToNextLevel: (json['pointsToNextLevel'] as num).toInt(),
      isMaxLevel: json['isMaxLevel'] as bool,
    );

Map<String, dynamic> _$UserPointsResponseToJson(UserPointsResponse instance) =>
    <String, dynamic>{
      'totalPoints': instance.totalPoints,
      'level': instance.level,
      'currentLevelThreshold': instance.currentLevelThreshold,
      'nextLevelThreshold': instance.nextLevelThreshold,
      'pointsToNextLevel': instance.pointsToNextLevel,
      'isMaxLevel': instance.isMaxLevel,
    };
