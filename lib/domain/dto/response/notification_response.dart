import 'package:json_annotation/json_annotation.dart';

part 'notification_response.g.dart';

@JsonSerializable()
class NotificationResponse {
  final String id;
  final String type;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String? deepLink;
  final String? actorId;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final String? entityId;
  final String? entityType;
  final bool read;
  final String createdAt;

  const NotificationResponse({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    this.deepLink,
    this.actorId,
    this.actorUsername,
    this.actorAvatarUrl,
    this.entityId,
    this.entityType,
    required this.read,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);
}

@JsonSerializable()
class UnreadCountResponse {
  final int count;

  const UnreadCountResponse({required this.count});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadCountResponseToJson(this);
}
