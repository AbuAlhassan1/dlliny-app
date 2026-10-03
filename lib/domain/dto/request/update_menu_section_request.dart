import 'package:json_annotation/json_annotation.dart';

part 'update_menu_section_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateMenuSectionRequest {
  final String? nameAr;
  final String? nameEn;
  final int? sortOrder;
  final bool? active;

  const UpdateMenuSectionRequest({
    this.nameAr,
    this.nameEn,
    this.sortOrder,
    this.active,
  });

  factory UpdateMenuSectionRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMenuSectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMenuSectionRequestToJson(this);
}
