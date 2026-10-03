import 'package:json_annotation/json_annotation.dart';

part 'create_business_transfer_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateBusinessTransferRequest {
  final String transferType;
  final String targetUserId;
  final String businessId;
  final String? venueId;
  final String? message;

  const CreateBusinessTransferRequest({
    required this.transferType,
    required this.targetUserId,
    required this.businessId,
    this.venueId,
    this.message,
  });

  factory CreateBusinessTransferRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBusinessTransferRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBusinessTransferRequestToJson(this);
}
