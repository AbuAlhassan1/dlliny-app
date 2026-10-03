// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_comment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCommentRequest _$CreateCommentRequestFromJson(
  Map<String, dynamic> json,
) => CreateCommentRequest(
  body: json['body'] as String,
  parentCommentId: json['parentCommentId'] as String?,
);

Map<String, dynamic> _$CreateCommentRequestToJson(
  CreateCommentRequest instance,
) => <String, dynamic>{
  'body': instance.body,
  'parentCommentId': ?instance.parentCommentId,
};
