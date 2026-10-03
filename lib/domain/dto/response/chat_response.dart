import 'package:json_annotation/json_annotation.dart';

import 'chat_enums.dart';

part 'chat_response.g.dart';

@JsonSerializable()
class ChatMemberResponse {
  final ChatMemberType memberType;
  final String memberId;
  final ChatMemberRole role;
  final String? displayName;
  final String? avatarUrl;

  const ChatMemberResponse({
    required this.memberType,
    required this.memberId,
    required this.role,
    this.displayName,
    this.avatarUrl,
  });

  factory ChatMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatMemberResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMemberResponseToJson(this);
}

@JsonSerializable()
class SharedResourcePreview {
  final SharedResourceType type;
  final String id;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final bool available;

  const SharedResourcePreview({
    required this.type,
    required this.id,
    this.title,
    this.subtitle,
    this.imageUrl,
    required this.available,
  });

  factory SharedResourcePreview.fromJson(Map<String, dynamic> json) =>
      _$SharedResourcePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$SharedResourcePreviewToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MessageResponse {
  final String id;
  final String conversationId;
  final ChatMemberType senderType;
  final String senderId;
  final MessageContentType contentType;
  final String? content;
  final String? audioUrl;
  final int? audioDurationSeconds;
  final String? audioWaveform;
  final SharedResourcePreview? sharedResource;
  final String? replyToMessageId;
  final bool deletedForEveryone;
  final String? editedAt;
  final String createdAt;

  const MessageResponse({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.contentType,
    this.content,
    this.audioUrl,
    this.audioDurationSeconds,
    this.audioWaveform,
    this.sharedResource,
    this.replyToMessageId,
    required this.deletedForEveryone,
    this.editedAt,
    required this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ConversationResponse {
  final String id;
  final ConversationType type;
  final String? title;
  final String? avatarUrl;
  final List<ChatMemberResponse> members;
  final MessageResponse? lastMessage;
  final int unreadCount;
  final ChatRequestState viewerRequestState;
  final bool muted;
  final int? retentionDays;
  final String createdAt;
  final String updatedAt;

  const ConversationResponse({
    required this.id,
    required this.type,
    this.title,
    this.avatarUrl,
    required this.members,
    this.lastMessage,
    required this.unreadCount,
    required this.viewerRequestState,
    required this.muted,
    this.retentionDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationResponseToJson(this);
}

@JsonSerializable()
class VoiceUploadUrlResponse {
  final String uploadUrl;
  final String key;

  const VoiceUploadUrlResponse({required this.uploadUrl, required this.key});

  factory VoiceUploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$VoiceUploadUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceUploadUrlResponseToJson(this);
}
