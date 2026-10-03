import 'package:json_annotation/json_annotation.dart';

part 'vibe_tag_catalog_response.g.dart';

@JsonSerializable(explicitToJson: false)
class VibeTagCatalogResponse {
  final String code;
  final String nameAr;
  final String nameEn;

  final String dimension;
  final int sortOrder;
  final bool active;
  final DateTime createdAt;

  const VibeTagCatalogResponse({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.dimension,
    required this.sortOrder,
    required this.active,
    required this.createdAt,
  });

  factory VibeTagCatalogResponse.fromJson(Map<String, dynamic> json) =>
      _$VibeTagCatalogResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VibeTagCatalogResponseToJson(this);
}
