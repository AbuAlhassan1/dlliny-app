import 'package:json_annotation/json_annotation.dart';

part 'featured_perk_response.g.dart';

@JsonSerializable()
class FeaturedPerkResponse {
  final String code;
  final String? labelAr;
  final String? labelEn;
  final String? descriptionAr;
  final String? descriptionEn;

  const FeaturedPerkResponse({
    required this.code,
    this.labelAr,
    this.labelEn,
    this.descriptionAr,
    this.descriptionEn,
  });

  String labelFor({required bool arabic}) {
    if (arabic) {
      return labelAr ?? labelEn ?? code;
    }
    return labelEn ?? labelAr ?? code;
  }

  String descriptionFor({required bool arabic}) {
    if (arabic) {
      return descriptionAr ?? descriptionEn ?? labelFor(arabic: true);
    }
    return descriptionEn ?? descriptionAr ?? labelFor(arabic: false);
  }

  factory FeaturedPerkResponse.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPerkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPerkResponseToJson(this);
}
