part of 'conversation_bloc.dart';

sealed class ConversationEvent {}

class ConversationOpened extends ConversationEvent {}

class OlderMessagesRequested extends ConversationEvent {}

class ConversationRefreshed extends ConversationEvent {}

class TextMessageSent extends ConversationEvent {
  final String content;
  final String? replyToId;
  TextMessageSent(this.content, {this.replyToId});
}

class MessageRetryRequested extends ConversationEvent {
  final String localId;
  MessageRetryRequested(this.localId);
}

class ReadMarkerAdvanced extends ConversationEvent {
  final String messageId;
  ReadMarkerAdvanced(this.messageId);
}

class MessageEditRequested extends ConversationEvent {
  final String messageId;
  final String newContent;
  MessageEditRequested(this.messageId, this.newContent);
}

class MessageDeleteRequested extends ConversationEvent {
  final String messageId;
  final String scope;
  MessageDeleteRequested(this.messageId, {required this.scope})
      : assert(scope == 'me' || scope == 'everyone');
}

class ConversationMutedRequested extends ConversationEvent {
  final bool muted;
  ConversationMutedRequested(this.muted);
}

class ConversationLeaveRequested extends ConversationEvent {}

class ConversationSettingsUpdated extends ConversationEvent {
  final String? title;
  final int? retentionDays;
  final bool clearRetention;
  ConversationSettingsUpdated({
    this.title,
    this.retentionDays,
    this.clearRetention = false,
  });
}

class MembersAddRequested extends ConversationEvent {
  final List<String> userIds;
  MembersAddRequested(this.userIds);
}

class MemberRemoveRequested extends ConversationEvent {
  final String userId;
  MemberRemoveRequested(this.userId);
}

class MemberRoleChangeRequested extends ConversationEvent {
  final String userId;
  final bool promoteToAdmin;
  MemberRoleChangeRequested(this.userId, {required this.promoteToAdmin});
}

class _WsEventReceived extends ConversationEvent {
  final ChatEvent event;
  _WsEventReceived(this.event);
}

class _TypingTimedOut extends ConversationEvent {
  final String memberId;
  _TypingTimedOut(this.memberId);
}

class VoiceMessageSent extends ConversationEvent {
  final String localFilePath;
  final String mimeType;
  final int durationSeconds;
  final String waveformJson;
  final String? replyToId;
  VoiceMessageSent({
    required this.localFilePath,
    required this.mimeType,
    required this.durationSeconds,
    required this.waveformJson,
    this.replyToId,
  });
}
