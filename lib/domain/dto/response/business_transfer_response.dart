import 'package:json_annotation/json_annotation.dart';

part 'business_transfer_response.g.dart';

@JsonSerializable()
class BusinessTransferResponse {
  final String id;
  final String transferType;
  final String status;
  final String senderUserId;
  final String senderUsername;
  final String targetUserId;
  final String targetUsername;
  final String businessId;
  final String? businessName;
  final String? venueId;
  final String? venueNameAr;
  final String? venueNameEn;
  final String? targetBusinessId;
  final String? targetBusinessName;
  final String? message;
  final String createdAt;
  final String? respondedAt;
  final String expiresAt;

  const BusinessTransferResponse({
    required this.id,
    required this.transferType,
    required this.status,
    required this.senderUserId,
    required this.senderUsername,
    required this.targetUserId,
    required this.targetUsername,
    required this.businessId,
    this.businessName,
    this.venueId,
    this.venueNameAr,
    this.venueNameEn,
    this.targetBusinessId,
    this.targetBusinessName,
    this.message,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
  });

  factory BusinessTransferResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessTransferResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessTransferResponseToJson(this);
}
