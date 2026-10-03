import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/core/realtime/chat_event.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/data/local/chat_cache_repository.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';

part 'chat_inbox_event.dart';
part 'chat_inbox_state.dart';

class ChatInboxBloc extends Bloc<ChatInboxEvent, ChatInboxState> {
  static const int _pageSize = 20;

  final ChatRepository _repo;
  final ChatEventSource _events;
  final ChatCacheRepository _cache;
  late final StreamSubscription<ChatEvent> _wsSub;

  ChatInboxBloc(this._repo, this._events, this._cache)
      : super(const ChatInboxState()) {
    on<InboxRequested>(_onRequested);
    on<InboxRefreshed>(_onRefreshed);
    on<InboxLoadMoreRequested>(_onLoadMore);
    on<InboxConversationOpened>(_onOpened);
    on<InboxConversationUpdated>(_onUpdated);
    on<InboxConversationRemoved>(_onRemoved);

    _wsSub = _events.events.listen(_onWsEvent);
  }

  void _onWsEvent(ChatEvent ev) {
    switch (ev) {
      case InboxRefreshHint _:
        add(InboxRefreshed());
        break;
      case MessageCreated _:
      case MessageEdited _:
      case MessageDeleted _:
      case ConversationUpdatedRemotely _:
      case RequestAcceptedRemotely _:
        add(InboxRefreshed());
        break;
      case MemberRemoved _:
        add(InboxRefreshed());
        break;
      default:
        break;
    }
  }

  @override
  Future<void> close() async {
    await _wsSub.cancel();
    return super.close();
  }

  Future<void> _onRequested(
    InboxRequested event,
    Emitter<ChatInboxState> emit,
  ) async {
    if (state.status == ChatInboxStatus.loading) return;
    final cached = await _cache.loadInbox();
    if (cached.isNotEmpty && state.conversations.isEmpty) {
      emit(state.copyWith(
        conversations: cached,
        status: ChatInboxStatus.loading,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(
        status: ChatInboxStatus.loading,
        clearError: true,
      ));
    }
    try {
      final page = await _repo.getInbox(page: 0, size: _pageSize);
      await _cache.upsertConversations(page.content);
      emit(
        state.copyWith(
          conversations: page.content,
          currentPage: 0,
          hasReachedEnd: page.last,
          status: ChatInboxStatus.success,
          clearError: true,
        ),
      );
    } on ChatException catch (e) {
      emit(
        state.copyWith(
          status: ChatInboxStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    InboxRefreshed event,
    Emitter<ChatInboxState> emit,
  ) async {
    emit(state.copyWith(status: ChatInboxStatus.refreshing, clearError: true));
    try {
      final page = await _repo.getInbox(page: 0, size: _pageSize);
      await _cache.upsertConversations(page.content);
      emit(
        state.copyWith(
          conversations: page.content,
          currentPage: 0,
          hasReachedEnd: page.last,
          status: ChatInboxStatus.success,
          clearError: true,
        ),
      );
    } on ChatException catch (e) {
      emit(
        state.copyWith(
          status: ChatInboxStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    InboxLoadMoreRequested event,
    Emitter<ChatInboxState> emit,
  ) async {
    if (state.hasReachedEnd ||
        state.status == ChatInboxStatus.loadingMore ||
        state.status == ChatInboxStatus.loading) {
      return;
    }
    emit(state.copyWith(status: ChatInboxStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getInbox(page: nextPage, size: _pageSize);
      emit(
        state.copyWith(
          conversations: [...state.conversations, ...page.content],
          currentPage: nextPage,
          hasReachedEnd: page.last,
          status: ChatInboxStatus.success,
        ),
      );
    } on ChatException catch (e) {
      emit(
        state.copyWith(
          status: ChatInboxStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  void _onOpened(
    InboxConversationOpened event,
    Emitter<ChatInboxState> emit,
  ) {
    final updated = state.conversations.map((c) {
      if (c.id != event.conversationId) return c;
      if (c.unreadCount == 0) return c;
      return ConversationResponse(
        id: c.id,
        type: c.type,
        title: c.title,
        avatarUrl: c.avatarUrl,
        members: c.members,
        lastMessage: c.lastMessage,
        unreadCount: 0,
        viewerRequestState: c.viewerRequestState,
        muted: c.muted,
        retentionDays: c.retentionDays,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );
    }).toList(growable: false);
    emit(state.copyWith(conversations: updated));
  }

  void _onUpdated(
    InboxConversationUpdated event,
    Emitter<ChatInboxState> emit,
  ) {
    final filtered = state.conversations
        .where((c) => c.id != event.conversation.id)
        .toList(growable: true);
    filtered.insert(0, event.conversation);
    emit(state.copyWith(conversations: filtered));
    _cache.upsertConversation(event.conversation);
  }

  void _onRemoved(
    InboxConversationRemoved event,
    Emitter<ChatInboxState> emit,
  ) {
    emit(
      state.copyWith(
        conversations: state.conversations
            .where((c) => c.id != event.conversationId)
            .toList(growable: false),
      ),
    );
    _cache.removeConversation(event.conversationId);
  }
}
