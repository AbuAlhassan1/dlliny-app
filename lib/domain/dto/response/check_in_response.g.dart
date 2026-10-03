// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckInResponse _$CheckInResponseFromJson(Map<String, dynamic> json) =>
    CheckInResponse(
      checkInId: json['checkInId'] as String,
      venueId: json['venueId'] as String,
      branchId: json['branchId'] as String,
      checkedInAt: json['checkedInAt'] as String,
      distanceMeters: (json['distanceMeters'] as num).toInt(),
    );

Map<String, dynamic> _$CheckInResponseToJson(CheckInResponse instance) =>
    <String, dynamic>{
      'checkInId': instance.checkInId,
      'venueId': instance.venueId,
      'branchId': instance.branchId,
      'checkedInAt': instance.checkedInAt,
      'distanceMeters': instance.distanceMeters,
    };
