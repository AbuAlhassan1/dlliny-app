import 'package:json_annotation/json_annotation.dart';

part 'update_vibe_tag_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateVibeTagRequest {
  final String? nameAr;
  final String? nameEn;
  final String? dimension;
  final int? sortOrder;
  final bool? active;

  const UpdateVibeTagRequest({
    this.nameAr,
    this.nameEn,
    this.dimension,
    this.sortOrder,
    this.active,
  });

  factory UpdateVibeTagRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateVibeTagRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateVibeTagRequestToJson(this);
}
