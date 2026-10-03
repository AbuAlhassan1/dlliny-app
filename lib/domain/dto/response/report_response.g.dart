// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportCategoryResponse _$ReportCategoryResponseFromJson(
  Map<String, dynamic> json,
) => ReportCategoryResponse(
  id: json['id'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  entityType: json['entityType'] as String,
  name: json['name'] as String?,
  active: json['active'] as bool?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$ReportCategoryResponseToJson(
  ReportCategoryResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'entityType': instance.entityType,
  'name': instance.name,
  'active': instance.active,
  'createdAt': instance.createdAt,
};

ReporterInfo _$ReporterInfoFromJson(Map<String, dynamic> json) => ReporterInfo(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
);

Map<String, dynamic> _$ReporterInfoToJson(ReporterInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
    };

CategoryInfo _$CategoryInfoFromJson(Map<String, dynamic> json) => CategoryInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  entityType: json['entityType'] as String,
);

Map<String, dynamic> _$CategoryInfoToJson(CategoryInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'entityType': instance.entityType,
    };

ContentReportResponse _$ContentReportResponseFromJson(
  Map<String, dynamic> json,
) => ContentReportResponse(
  id: json['id'] as String,
  reporter: ReporterInfo.fromJson(json['reporter'] as Map<String, dynamic>),
  category: json['category'] == null
      ? null
      : CategoryInfo.fromJson(json['category'] as Map<String, dynamic>),
  entityId: json['entityId'] as String?,
  description: json['description'] as String?,
  status: json['status'] as String,
  actionTaken: json['actionTaken'] as String?,
  createdAt: json['createdAt'] as String,
  reviewedAt: json['reviewedAt'] as String?,
);

Map<String, dynamic> _$ContentReportResponseToJson(
  ContentReportResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'reporter': instance.reporter.toJson(),
  'category': instance.category?.toJson(),
  'entityId': instance.entityId,
  'description': instance.description,
  'status': instance.status,
  'actionTaken': instance.actionTaken,
  'createdAt': instance.createdAt,
  'reviewedAt': instance.reviewedAt,
};
