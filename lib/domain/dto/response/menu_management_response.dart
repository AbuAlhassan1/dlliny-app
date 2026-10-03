import 'package:json_annotation/json_annotation.dart';

part 'menu_management_response.g.dart';

@JsonSerializable()
class MenuItemResponse {
  final String id;
  final String sectionId;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;

  final double? price;

  final String? imageUrl;

  final bool available;

  final int sortOrder;

  const MenuItemResponse({
    required this.id,
    required this.sectionId,
    required this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.price,
    this.imageUrl,
    required this.available,
    required this.sortOrder,
  });

  factory MenuItemResponse.fromJson(Map<String, dynamic> json) =>
      _$MenuItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MenuSectionResponse {
  final String id;
  final String nameAr;
  final String? nameEn;
  final int sortOrder;
  final bool active;
  @JsonKey(defaultValue: <MenuItemResponse>[])
  final List<MenuItemResponse> items;

  const MenuSectionResponse({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.sortOrder,
    required this.active,
    this.items = const [],
  });

  factory MenuSectionResponse.fromJson(Map<String, dynamic> json) =>
      _$MenuSectionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MenuSectionResponseToJson(this);
}

@JsonSerializable()
class MenuItemImageUploadResponse {
  final String uploadUrl;
  final String key;

  const MenuItemImageUploadResponse({
    required this.uploadUrl,
    required this.key,
  });

  factory MenuItemImageUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$MenuItemImageUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemImageUploadResponseToJson(this);
}
