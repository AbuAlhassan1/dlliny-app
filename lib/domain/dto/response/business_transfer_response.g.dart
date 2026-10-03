// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_transfer_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessTransferResponse _$BusinessTransferResponseFromJson(
  Map<String, dynamic> json,
) => BusinessTransferResponse(
  id: json['id'] as String,
  transferType: json['transferType'] as String,
  status: json['status'] as String,
  senderUserId: json['senderUserId'] as String,
  senderUsername: json['senderUsername'] as String,
  targetUserId: json['targetUserId'] as String,
  targetUsername: json['targetUsername'] as String,
  businessId: json['businessId'] as String,
  businessName: json['businessName'] as String?,
  venueId: json['venueId'] as String?,
  venueNameAr: json['venueNameAr'] as String?,
  venueNameEn: json['venueNameEn'] as String?,
  targetBusinessId: json['targetBusinessId'] as String?,
  targetBusinessName: json['targetBusinessName'] as String?,
  message: json['message'] as String?,
  createdAt: json['createdAt'] as String,
  respondedAt: json['respondedAt'] as String?,
  expiresAt: json['expiresAt'] as String,
);

Map<String, dynamic> _$BusinessTransferResponseToJson(
  BusinessTransferResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'transferType': instance.transferType,
  'status': instance.status,
  'senderUserId': instance.senderUserId,
  'senderUsername': instance.senderUsername,
  'targetUserId': instance.targetUserId,
  'targetUsername': instance.targetUsername,
  'businessId': instance.businessId,
  'businessName': instance.businessName,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'targetBusinessId': instance.targetBusinessId,
  'targetBusinessName': instance.targetBusinessName,
  'message': instance.message,
  'createdAt': instance.createdAt,
  'respondedAt': instance.respondedAt,
  'expiresAt': instance.expiresAt,
};
