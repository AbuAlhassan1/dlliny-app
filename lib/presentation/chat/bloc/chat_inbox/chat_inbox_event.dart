part of 'chat_inbox_bloc.dart';

sealed class ChatInboxEvent {}

class InboxRequested extends ChatInboxEvent {}

class InboxRefreshed extends ChatInboxEvent {}

class InboxLoadMoreRequested extends ChatInboxEvent {}

class InboxConversationOpened extends ChatInboxEvent {
  final String conversationId;
  InboxConversationOpened(this.conversationId);
}

class InboxConversationUpdated extends ChatInboxEvent {
  final ConversationResponse conversation;
  InboxConversationUpdated(this.conversation);
}

class InboxConversationRemoved extends ChatInboxEvent {
  final String conversationId;
  InboxConversationRemoved(this.conversationId);
}
