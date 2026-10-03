// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportPostRequest _$ReportPostRequestFromJson(Map<String, dynamic> json) =>
    ReportPostRequest(
      categoryId: json['categoryId'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ReportPostRequestToJson(ReportPostRequest instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'description': instance.description,
    };
