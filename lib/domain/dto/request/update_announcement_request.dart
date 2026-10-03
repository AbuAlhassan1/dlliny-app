import 'package:json_annotation/json_annotation.dart';

part 'update_announcement_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateAnnouncementRequest {
  final String? titleAr;
  final String? titleEn;
  final String? bodyAr;
  final String? bodyEn;
  final bool? pinned;
  final bool? active;

  final String? expiresAt;

  const UpdateAnnouncementRequest({
    this.titleAr,
    this.titleEn,
    this.bodyAr,
    this.bodyEn,
    this.pinned,
    this.active,
    this.expiresAt,
  });

  factory UpdateAnnouncementRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAnnouncementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateAnnouncementRequestToJson(this);
}
