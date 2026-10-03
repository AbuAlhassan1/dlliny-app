part of 'conversation_bloc.dart';

enum ConversationStatus {
  initial,
  loading,
  refreshing,
  loadingMore,
  success,
  failure,
}

class ConversationState {
  final List<MessageDisplayItem> messages;
  final int currentPage;
  final bool hasReachedEnd;
  final ConversationResponse? conversation;
  final ConversationStatus status;
  final String? errorMessage;

  final bool isLeft;

  final Map<String, DateTime> typingByMember;

  final String? peerReadMessageId;

  final bool? peerOnline;
  final String? peerLastSeenAt;

  const ConversationState({
    this.messages = const [],
    this.currentPage = 0,
    this.hasReachedEnd = false,
    this.conversation,
    this.status = ConversationStatus.initial,
    this.errorMessage,
    this.isLeft = false,
    this.typingByMember = const {},
    this.peerReadMessageId,
    this.peerOnline,
    this.peerLastSeenAt,
  });

  bool get isLoading => status == ConversationStatus.loading;
  bool get isLoadingMore => status == ConversationStatus.loadingMore;
  bool get isRefreshing => status == ConversationStatus.refreshing;
  bool get hasFailed => status == ConversationStatus.failure;
  bool get isPendingRequest =>
      conversation?.viewerRequestState == ChatRequestState.pending;

  ConversationState copyWith({
    List<MessageDisplayItem>? messages,
    int? currentPage,
    bool? hasReachedEnd,
    ConversationResponse? conversation,
    ConversationStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? isLeft,
    Map<String, DateTime>? typingByMember,
    String? peerReadMessageId,
    bool? peerOnline,
    String? peerLastSeenAt,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      conversation: conversation ?? this.conversation,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLeft: isLeft ?? this.isLeft,
      typingByMember: typingByMember ?? this.typingByMember,
      peerReadMessageId: peerReadMessageId ?? this.peerReadMessageId,
      peerOnline: peerOnline ?? this.peerOnline,
      peerLastSeenAt: peerLastSeenAt ?? this.peerLastSeenAt,
    );
  }
}
