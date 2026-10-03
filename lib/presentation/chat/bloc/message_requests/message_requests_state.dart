part of 'message_requests_bloc.dart';

enum MessageRequestsStatus {
  initial,
  loading,
  refreshing,
  loadingMore,
  success,
  failure,
}

class MessageRequestsState {
  final List<ConversationResponse> requests;
  final int currentPage;
  final bool hasReachedEnd;
  final MessageRequestsStatus status;
  final String? errorMessage;

  final Set<String> inFlightIds;

  const MessageRequestsState({
    this.requests = const [],
    this.currentPage = 0,
    this.hasReachedEnd = false,
    this.status = MessageRequestsStatus.initial,
    this.errorMessage,
    this.inFlightIds = const {},
  });

  bool get isLoading => status == MessageRequestsStatus.loading;
  bool get isLoadingMore => status == MessageRequestsStatus.loadingMore;
  bool get isRefreshing => status == MessageRequestsStatus.refreshing;
  bool get hasFailed => status == MessageRequestsStatus.failure;
  int get pendingCount => requests.length;

  MessageRequestsState copyWith({
    List<ConversationResponse>? requests,
    int? currentPage,
    bool? hasReachedEnd,
    MessageRequestsStatus? status,
    String? errorMessage,
    Set<String>? inFlightIds,
    bool clearError = false,
  }) {
    return MessageRequestsState(
      requests: requests ?? this.requests,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      inFlightIds: inFlightIds ?? this.inFlightIds,
    );
  }
}
