// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_conversation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateConversationRequest _$CreateConversationRequestFromJson(
  Map<String, dynamic> json,
) => CreateConversationRequest(
  type: $enumDecode(_$ConversationTypeEnumMap, json['type']),
  participants: (json['participants'] as List<dynamic>)
      .map((e) => Participant.fromJson(e as Map<String, dynamic>))
      .toList(),
  title: json['title'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$CreateConversationRequestToJson(
  CreateConversationRequest instance,
) => <String, dynamic>{
  'type': _$ConversationTypeEnumMap[instance.type]!,
  'participants': instance.participants.map((e) => e.toJson()).toList(),
  'title': ?instance.title,
  'avatarUrl': ?instance.avatarUrl,
};

const _$ConversationTypeEnumMap = {
  ConversationType.direct: 'DIRECT',
  ConversationType.group: 'GROUP',
};

Participant _$ParticipantFromJson(Map<String, dynamic> json) => Participant(
  type: $enumDecode(_$ChatMemberTypeEnumMap, json['type']),
  id: json['id'] as String,
);

Map<String, dynamic> _$ParticipantToJson(Participant instance) =>
    <String, dynamic>{
      'type': _$ChatMemberTypeEnumMap[instance.type]!,
      'id': instance.id,
    };

const _$ChatMemberTypeEnumMap = {
  ChatMemberType.user: 'USER',
  ChatMemberType.venue: 'VENUE',
};
