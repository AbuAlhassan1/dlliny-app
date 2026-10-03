import 'package:json_annotation/json_annotation.dart';

part 'report_response.g.dart';

@JsonSerializable()
class ReportCategoryResponse {
  final String id;

  final String nameAr;

  final String nameEn;

  final String entityType;

  final String? name;

  final bool? active;

  final String? createdAt;

  const ReportCategoryResponse({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.entityType,
    this.name,
    this.active,
    this.createdAt,
  });

  factory ReportCategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$ReportCategoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReportCategoryResponseToJson(this);
}

@JsonSerializable()
class ReporterInfo {
  final String id;
  final String username;
  final String? displayName;

  const ReporterInfo({
    required this.id,
    required this.username,
    this.displayName,
  });

  factory ReporterInfo.fromJson(Map<String, dynamic> json) =>
      _$ReporterInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReporterInfoToJson(this);
}

@JsonSerializable()
class CategoryInfo {
  final String id;
  final String name;
  final String entityType;

  const CategoryInfo({
    required this.id,
    required this.name,
    required this.entityType,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) =>
      _$CategoryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ContentReportResponse {
  final String id;
  final ReporterInfo reporter;
  final CategoryInfo? category;
  final String? entityId;
  final String? description;
  final String status;
  final String? actionTaken;
  final String createdAt;
  final String? reviewedAt;

  const ContentReportResponse({
    required this.id,
    required this.reporter,
    this.category,
    this.entityId,
    this.description,
    required this.status,
    this.actionTaken,
    required this.createdAt,
    this.reviewedAt,
  });

  factory ContentReportResponse.fromJson(Map<String, dynamic> json) =>
      _$ContentReportResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ContentReportResponseToJson(this);
}
