// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_service_management_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VenueServiceResponse _$VenueServiceResponseFromJson(
  Map<String, dynamic> json,
) => VenueServiceResponse(
  id: json['id'] as String,
  serviceTypeId: (json['serviceTypeId'] as num).toInt(),
  serviceTypeCode: json['serviceTypeCode'] as String,
  serviceTypeNameAr: json['serviceTypeNameAr'] as String,
  serviceTypeNameEn: json['serviceTypeNameEn'] as String,
  category: json['category'] as String,
  price: (json['price'] as num?)?.toDouble(),
  imageUrl: json['imageUrl'] as String?,
  active: json['active'] as bool,
);

Map<String, dynamic> _$VenueServiceResponseToJson(
  VenueServiceResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'serviceTypeId': instance.serviceTypeId,
  'serviceTypeCode': instance.serviceTypeCode,
  'serviceTypeNameAr': instance.serviceTypeNameAr,
  'serviceTypeNameEn': instance.serviceTypeNameEn,
  'category': instance.category,
  'price': instance.price,
  'imageUrl': instance.imageUrl,
  'active': instance.active,
};

ServiceImageUploadResponse _$ServiceImageUploadResponseFromJson(
  Map<String, dynamic> json,
) => ServiceImageUploadResponse(
  uploadUrl: json['uploadUrl'] as String,
  key: json['key'] as String,
);

Map<String, dynamic> _$ServiceImageUploadResponseToJson(
  ServiceImageUploadResponse instance,
) => <String, dynamic>{'uploadUrl': instance.uploadUrl, 'key': instance.key};
