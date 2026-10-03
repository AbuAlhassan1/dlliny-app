import 'package:json_annotation/json_annotation.dart';

part 'create_announcement_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateAnnouncementRequest {
  final String titleAr;
  final String? titleEn;
  final String bodyAr;
  final String? bodyEn;

  final bool pinned;

  final String? publishedAt;

  final String? expiresAt;

  const CreateAnnouncementRequest({
    required this.titleAr,
    this.titleEn,
    required this.bodyAr,
    this.bodyEn,
    this.pinned = false,
    this.publishedAt,
    this.expiresAt,
  });

  factory CreateAnnouncementRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAnnouncementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAnnouncementRequestToJson(this);
}
