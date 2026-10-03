part of 'message_requests_bloc.dart';

sealed class MessageRequestsEvent {}

class MessageRequestsRequested extends MessageRequestsEvent {}
class MessageRequestsRefreshed extends MessageRequestsEvent {}
class MessageRequestsLoadMoreRequested extends MessageRequestsEvent {}

class MessageRequestAccepted extends MessageRequestsEvent {
  final String conversationId;
  MessageRequestAccepted(this.conversationId);
}

class MessageRequestRejected extends MessageRequestsEvent {
  final String conversationId;
  MessageRequestRejected(this.conversationId);
}
