part of 'chat_inbox_bloc.dart';

enum ChatInboxStatus {
  initial,
  loading,
  refreshing,
  loadingMore,
  success,
  failure,
}

class ChatInboxState {
  final List<ConversationResponse> conversations;
  final int currentPage;
  final bool hasReachedEnd;
  final ChatInboxStatus status;
  final String? errorMessage;

  const ChatInboxState({
    this.conversations = const [],
    this.currentPage = 0,
    this.hasReachedEnd = false,
    this.status = ChatInboxStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == ChatInboxStatus.loading;
  bool get isLoadingMore => status == ChatInboxStatus.loadingMore;
  bool get isRefreshing => status == ChatInboxStatus.refreshing;
  bool get hasFailed => status == ChatInboxStatus.failure;

  int get totalUnread =>
      conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  ChatInboxState copyWith({
    List<ConversationResponse>? conversations,
    int? currentPage,
    bool? hasReachedEnd,
    ChatInboxStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatInboxState(
      conversations: conversations ?? this.conversations,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
