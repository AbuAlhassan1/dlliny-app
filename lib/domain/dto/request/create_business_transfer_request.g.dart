// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_business_transfer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBusinessTransferRequest _$CreateBusinessTransferRequestFromJson(
  Map<String, dynamic> json,
) => CreateBusinessTransferRequest(
  transferType: json['transferType'] as String,
  targetUserId: json['targetUserId'] as String,
  businessId: json['businessId'] as String,
  venueId: json['venueId'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$CreateBusinessTransferRequestToJson(
  CreateBusinessTransferRequest instance,
) => <String, dynamic>{
  'transferType': instance.transferType,
  'targetUserId': instance.targetUserId,
  'businessId': instance.businessId,
  'venueId': ?instance.venueId,
  'message': ?instance.message,
};
