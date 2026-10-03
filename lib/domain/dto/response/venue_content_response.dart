import 'package:json_annotation/json_annotation.dart';

part 'venue_content_response.g.dart';

@JsonSerializable()
class VenueServiceTypeDto {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;

  final String category;
  final int sortOrder;

  const VenueServiceTypeDto({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.sortOrder,
  });

  factory VenueServiceTypeDto.fromJson(Map<String, dynamic> json) =>
      _$VenueServiceTypeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueServiceTypeDtoToJson(this);
}

@JsonSerializable()
class VenueServiceItemDto {
  final String id;
  final int serviceTypeId;
  final String code;
  final String nameAr;
  final String nameEn;
  final String category;

  final double? price;

  final String? imageUrl;

  const VenueServiceItemDto({
    required this.id,
    required this.serviceTypeId,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    this.price,
    this.imageUrl,
  });

  factory VenueServiceItemDto.fromJson(Map<String, dynamic> json) =>
      _$VenueServiceItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueServiceItemDtoToJson(this);
}

@JsonSerializable()
class VenueAnnouncementDto {
  final String id;
  final String titleAr;
  final String? titleEn;
  final String bodyAr;
  final String? bodyEn;
  final bool pinned;

  final String publishedAt;
  final String? expiresAt;

  const VenueAnnouncementDto({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.bodyAr,
    this.bodyEn,
    required this.pinned,
    required this.publishedAt,
    this.expiresAt,
  });

  factory VenueAnnouncementDto.fromJson(Map<String, dynamic> json) =>
      _$VenueAnnouncementDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueAnnouncementDtoToJson(this);
}

@JsonSerializable()
class MenuItemDto {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? price;

  final String? imageUrl;
  final int sortOrder;

  const MenuItemDto({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.price,
    this.imageUrl,
    required this.sortOrder,
  });

  factory MenuItemDto.fromJson(Map<String, dynamic> json) =>
      _$MenuItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MenuSectionDto {
  final String id;
  final String nameAr;
  final String? nameEn;
  final int sortOrder;
  @JsonKey(defaultValue: <MenuItemDto>[])
  final List<MenuItemDto> items;

  const MenuSectionDto({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.sortOrder,
    this.items = const [],
  });

  factory MenuSectionDto.fromJson(Map<String, dynamic> json) =>
      _$MenuSectionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MenuSectionDtoToJson(this);
}
