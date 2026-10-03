import 'package:json_annotation/json_annotation.dart';

part 'create_vibe_tag_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateVibeTagRequest {
  final String code;
  final String nameAr;
  final String nameEn;

  final String dimension;
  final int? sortOrder;

  const CreateVibeTagRequest({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.dimension,
    this.sortOrder,
  });

  factory CreateVibeTagRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateVibeTagRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateVibeTagRequestToJson(this);
}
