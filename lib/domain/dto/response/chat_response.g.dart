// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMemberResponse _$ChatMemberResponseFromJson(Map<String, dynamic> json) =>
    ChatMemberResponse(
      memberType: $enumDecode(_$ChatMemberTypeEnumMap, json['memberType']),
      memberId: json['memberId'] as String,
      role: $enumDecode(_$ChatMemberRoleEnumMap, json['role']),
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$ChatMemberResponseToJson(ChatMemberResponse instance) =>
    <String, dynamic>{
      'memberType': _$ChatMemberTypeEnumMap[instance.memberType]!,
      'memberId': instance.memberId,
      'role': _$ChatMemberRoleEnumMap[instance.role]!,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

const _$ChatMemberTypeEnumMap = {
  ChatMemberType.user: 'USER',
  ChatMemberType.venue: 'VENUE',
};

const _$ChatMemberRoleEnumMap = {
  ChatMemberRole.member: 'MEMBER',
  ChatMemberRole.admin: 'ADMIN',
};

SharedResourcePreview _$SharedResourcePreviewFromJson(
  Map<String, dynamic> json,
) => SharedResourcePreview(
  type: $enumDecode(_$SharedResourceTypeEnumMap, json['type']),
  id: json['id'] as String,
  title: json['title'] as String?,
  subtitle: json['subtitle'] as String?,
  imageUrl: json['imageUrl'] as String?,
  available: json['available'] as bool,
);

Map<String, dynamic> _$SharedResourcePreviewToJson(
  SharedResourcePreview instance,
) => <String, dynamic>{
  'type': _$SharedResourceTypeEnumMap[instance.type]!,
  'id': instance.id,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'imageUrl': instance.imageUrl,
  'available': instance.available,
};

const _$SharedResourceTypeEnumMap = {
  SharedResourceType.post: 'POST',
  SharedResourceType.hangout: 'HANGOUT',
  SharedResourceType.venue: 'VENUE',
  SharedResourceType.user: 'USER',
  SharedResourceType.memory: 'MEMORY',
};

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderType: $enumDecode(_$ChatMemberTypeEnumMap, json['senderType']),
      senderId: json['senderId'] as String,
      contentType: $enumDecode(
        _$MessageContentTypeEnumMap,
        json['contentType'],
      ),
      content: json['content'] as String?,
      audioUrl: json['audioUrl'] as String?,
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(),
      audioWaveform: json['audioWaveform'] as String?,
      sharedResource: json['sharedResource'] == null
          ? null
          : SharedResourcePreview.fromJson(
              json['sharedResource'] as Map<String, dynamic>,
            ),
      replyToMessageId: json['replyToMessageId'] as String?,
      deletedForEveryone: json['deletedForEveryone'] as bool,
      editedAt: json['editedAt'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderType': _$ChatMemberTypeEnumMap[instance.senderType]!,
      'senderId': instance.senderId,
      'contentType': _$MessageContentTypeEnumMap[instance.contentType]!,
      'content': instance.content,
      'audioUrl': instance.audioUrl,
      'audioDurationSeconds': instance.audioDurationSeconds,
      'audioWaveform': instance.audioWaveform,
      'sharedResource': instance.sharedResource?.toJson(),
      'replyToMessageId': instance.replyToMessageId,
      'deletedForEveryone': instance.deletedForEveryone,
      'editedAt': instance.editedAt,
      'createdAt': instance.createdAt,
    };

const _$MessageContentTypeEnumMap = {
  MessageContentType.text: 'TEXT',
  MessageContentType.voice: 'VOICE',
  MessageContentType.share: 'SHARE',
};

ConversationResponse _$ConversationResponseFromJson(
  Map<String, dynamic> json,
) => ConversationResponse(
  id: json['id'] as String,
  type: $enumDecode(_$ConversationTypeEnumMap, json['type']),
  title: json['title'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  members: (json['members'] as List<dynamic>)
      .map((e) => ChatMemberResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastMessage: json['lastMessage'] == null
      ? null
      : MessageResponse.fromJson(json['lastMessage'] as Map<String, dynamic>),
  unreadCount: (json['unreadCount'] as num).toInt(),
  viewerRequestState: $enumDecode(
    _$ChatRequestStateEnumMap,
    json['viewerRequestState'],
  ),
  muted: json['muted'] as bool,
  retentionDays: (json['retentionDays'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$ConversationResponseToJson(
  ConversationResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': _$ConversationTypeEnumMap[instance.type]!,
  'title': instance.title,
  'avatarUrl': instance.avatarUrl,
  'members': instance.members.map((e) => e.toJson()).toList(),
  'lastMessage': instance.lastMessage?.toJson(),
  'unreadCount': instance.unreadCount,
  'viewerRequestState': _$ChatRequestStateEnumMap[instance.viewerRequestState]!,
  'muted': instance.muted,
  'retentionDays': instance.retentionDays,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

const _$ConversationTypeEnumMap = {
  ConversationType.direct: 'DIRECT',
  ConversationType.group: 'GROUP',
};

const _$ChatRequestStateEnumMap = {
  ChatRequestState.pending: 'PENDING',
  ChatRequestState.accepted: 'ACCEPTED',
};

VoiceUploadUrlResponse _$VoiceUploadUrlResponseFromJson(
  Map<String, dynamic> json,
) => VoiceUploadUrlResponse(
  uploadUrl: json['uploadUrl'] as String,
  key: json['key'] as String,
);

Map<String, dynamic> _$VoiceUploadUrlResponseToJson(
  VoiceUploadUrlResponse instance,
) => <String, dynamic>{'uploadUrl': instance.uploadUrl, 'key': instance.key};
