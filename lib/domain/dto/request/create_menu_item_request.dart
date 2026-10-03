import 'package:json_annotation/json_annotation.dart';

part 'create_menu_item_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateMenuItemRequest {
  final String sectionId;

  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;

  final double? price;

  final String? imageUrl;

  final int sortOrder;

  const CreateMenuItemRequest({
    required this.sectionId,
    required this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.price,
    this.imageUrl,
    required this.sortOrder,
  });

  factory CreateMenuItemRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMenuItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMenuItemRequestToJson(this);
}
