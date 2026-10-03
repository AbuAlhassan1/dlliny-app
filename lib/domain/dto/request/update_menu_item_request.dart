import 'package:json_annotation/json_annotation.dart';

part 'update_menu_item_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateMenuItemRequest {
  final String? sectionId;

  final String? nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? price;
  final String? imageUrl;
  final bool? available;
  final int? sortOrder;

  const UpdateMenuItemRequest({
    this.sectionId,
    this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.price,
    this.imageUrl,
    this.available,
    this.sortOrder,
  });

  factory UpdateMenuItemRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMenuItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMenuItemRequestToJson(this);
}
