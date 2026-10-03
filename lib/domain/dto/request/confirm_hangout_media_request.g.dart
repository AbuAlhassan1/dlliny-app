// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_hangout_media_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfirmHangoutMediaRequest _$ConfirmHangoutMediaRequestFromJson(
  Map<String, dynamic> json,
) => ConfirmHangoutMediaRequest(
  key: json['key'] as String,
  mediaType: json['mediaType'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ConfirmHangoutMediaRequestToJson(
  ConfirmHangoutMediaRequest instance,
) => <String, dynamic>{
  'key': instance.key,
  'mediaType': instance.mediaType,
  'sortOrder': instance.sortOrder,
  'aspectRatio': instance.aspectRatio,
};
