import 'package:json_annotation/json_annotation.dart';

import '../request/broadcast_request.dart';

part 'admin_broadcast_response.g.dart';

enum BroadcastStatus {
  queued,

  inProgress,

  completed,

  failed,
}

@JsonSerializable(explicitToJson: true)
class AdminBroadcastResponse {
  final String id;
  final String sentByAdminId;

  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String? deepLink;

  @JsonKey(toJson: _audienceTypeToJson, fromJson: _audienceTypeFromJson)
  final BroadcastAudienceType audienceType;

  final String audienceTargetId;
  final int audienceCount;

  final int inAppSuccessCount;
  final int pushSuccessCount;
  final int pushFailureCount;

  @JsonKey(toJson: _statusToJson, fromJson: _statusFromJson)
  final BroadcastStatus status;

  final String? failureReason;

  final DateTime createdAt;
  final DateTime? completedAt;

  const AdminBroadcastResponse({
    required this.id,
    required this.sentByAdminId,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    this.deepLink,
    required this.audienceType,
    required this.audienceTargetId,
    required this.audienceCount,
    required this.inAppSuccessCount,
    required this.pushSuccessCount,
    required this.pushFailureCount,
    required this.status,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
  });

  factory AdminBroadcastResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminBroadcastResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AdminBroadcastResponseToJson(this);
}

String _audienceTypeToJson(BroadcastAudienceType t) => t.name.toUpperCase();
BroadcastAudienceType _audienceTypeFromJson(String s) =>
    BroadcastAudienceType.values.firstWhere(
      (e) => e.name.toUpperCase() == s.toUpperCase(),
      orElse: () => BroadcastAudienceType.user,
    );

String _statusToJson(BroadcastStatus s) => switch (s) {
      BroadcastStatus.queued => 'QUEUED',
      BroadcastStatus.inProgress => 'IN_PROGRESS',
      BroadcastStatus.completed => 'COMPLETED',
      BroadcastStatus.failed => 'FAILED',
    };

BroadcastStatus _statusFromJson(String s) => switch (s.toUpperCase()) {
      'QUEUED' => BroadcastStatus.queued,
      'IN_PROGRESS' => BroadcastStatus.inProgress,
      'COMPLETED' => BroadcastStatus.completed,
      'FAILED' => BroadcastStatus.failed,
      _ => BroadcastStatus.queued,
    };
