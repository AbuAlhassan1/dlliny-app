// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_conversation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateConversationRequest _$UpdateConversationRequestFromJson(
  Map<String, dynamic> json,
) => UpdateConversationRequest(
  title: json['title'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  retentionDays: (json['retentionDays'] as num?)?.toInt(),
);

Map<String, dynamic> _$UpdateConversationRequestToJson(
  UpdateConversationRequest instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'avatarUrl': ?instance.avatarUrl,
  'retentionDays': ?instance.retentionDays,
};
