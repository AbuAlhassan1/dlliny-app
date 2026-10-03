import 'package:json_annotation/json_annotation.dart';

part 'create_menu_section_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateMenuSectionRequest {
  final String nameAr;

  final String? nameEn;

  final int sortOrder;

  const CreateMenuSectionRequest({
    required this.nameAr,
    this.nameEn,
    required this.sortOrder,
  });

  factory CreateMenuSectionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMenuSectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMenuSectionRequestToJson(this);
}
