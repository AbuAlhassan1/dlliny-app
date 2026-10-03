// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_hangout_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportHangoutRequest _$ReportHangoutRequestFromJson(
  Map<String, dynamic> json,
) => ReportHangoutRequest(
  categoryId: json['categoryId'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ReportHangoutRequestToJson(
  ReportHangoutRequest instance,
) => <String, dynamic>{
  'categoryId': instance.categoryId,
  'description': instance.description,
};
