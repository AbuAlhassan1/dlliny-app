import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';

sealed class ChatEvent {
  final String conversationId;
  const ChatEvent(this.conversationId);
}

class MessageCreated extends ChatEvent {
  final MessageResponse message;
  const MessageCreated(super.conversationId, this.message);
}

class MessageEdited extends ChatEvent {
  final MessageResponse message;
  const MessageEdited(super.conversationId, this.message);
}

class MessageDeleted extends ChatEvent {
  final String messageId;
  const MessageDeleted(super.conversationId, this.messageId);
}

class ReadReceiptReceived extends ChatEvent {
  final String memberId;
  final ChatMemberType memberType;
  final String upToMessageId;
  const ReadReceiptReceived(
    super.conversationId, {
    required this.memberId,
    required this.memberType,
    required this.upToMessageId,
  });
}

class TypingChanged extends ChatEvent {
  final String memberId;
  final ChatMemberType memberType;
  final bool typing;
  const TypingChanged(
    super.conversationId, {
    required this.memberId,
    required this.memberType,
    required this.typing,
  });
}

class RequestAcceptedRemotely extends ChatEvent {
  const RequestAcceptedRemotely(super.conversationId);
}

class MemberAdded extends ChatEvent {
  final List<ChatMemberResponse> members;
  const MemberAdded(super.conversationId, this.members);
}

class MemberRemoved extends ChatEvent {
  final String memberId;
  final ChatMemberType memberType;
  const MemberRemoved(
    super.conversationId, {
    required this.memberId,
    required this.memberType,
  });
}

class MemberRoleChanged extends ChatEvent {
  final String memberId;
  final ChatMemberType memberType;
  final ChatMemberRole role;
  const MemberRoleChanged(
    super.conversationId, {
    required this.memberId,
    required this.memberType,
    required this.role,
  });
}

class ConversationUpdatedRemotely extends ChatEvent {
  final ConversationResponse conversation;
  const ConversationUpdatedRemotely(
    super.conversationId,
    this.conversation,
  );
}

class InboxRefreshHint extends ChatEvent {
  final ChatRequestState landedIn;
  const InboxRefreshHint(super.conversationId, this.landedIn);
}

class PresenceChanged extends ChatEvent {
  final String userId;
  final bool online;
  final String? lastSeenAt;
  const PresenceChanged({
    required this.userId,
    required this.online,
    this.lastSeenAt,
  }) : super('');
}
