import 'package:json_annotation/json_annotation.dart';

part 'announcement_management_response.g.dart';

@JsonSerializable()
class AnnouncementResponse {
  final String id;
  final String titleAr;
  final String? titleEn;
  final String bodyAr;
  final String? bodyEn;
  final bool pinned;

  final bool active;

  final String? publishedAt;

  final String? expiresAt;

  final String createdAt;

  const AnnouncementResponse({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.bodyAr,
    this.bodyEn,
    required this.pinned,
    required this.active,
    this.publishedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementResponseToJson(this);
}
