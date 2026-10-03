import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/core/realtime/chat_event.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';

part 'message_requests_event.dart';
part 'message_requests_state.dart';

class MessageRequestsBloc
    extends Bloc<MessageRequestsEvent, MessageRequestsState> {
  static const int _pageSize = 20;

  final ChatRepository _repo;
  final ChatInboxBloc _inbox;
  final ChatEventSource _events;
  late final StreamSubscription<ChatEvent> _wsSub;

  MessageRequestsBloc(this._repo, this._inbox, this._events)
      : super(const MessageRequestsState()) {
    on<MessageRequestsRequested>(_onRequested);
    on<MessageRequestsRefreshed>(_onRefreshed);
    on<MessageRequestsLoadMoreRequested>(_onLoadMore);
    on<MessageRequestAccepted>(_onAccepted);
    on<MessageRequestRejected>(_onRejected);

    _wsSub = _events.events.listen(_onWsEvent);
  }

  void _onWsEvent(ChatEvent ev) {
    if (ev is InboxRefreshHint && ev.landedIn == ChatRequestState.pending) {
      add(MessageRequestsRefreshed());
      return;
    }
    if (ev is RequestAcceptedRemotely) {
      add(MessageRequestsRefreshed());
    }
  }

  @override
  Future<void> close() async {
    await _wsSub.cancel();
    return super.close();
  }

  Future<void> _onRequested(
    MessageRequestsRequested event,
    Emitter<MessageRequestsState> emit,
  ) async {
    if (state.status == MessageRequestsStatus.loading) return;
    emit(state.copyWith(
      status: MessageRequestsStatus.loading,
      clearError: true,
    ));
    try {
      final page = await _repo.getMessageRequests(page: 0, size: _pageSize);
      emit(state.copyWith(
        requests: page.content,
        currentPage: 0,
        hasReachedEnd: page.last,
        status: MessageRequestsStatus.success,
        clearError: true,
      ));
    } on ChatException catch (e) {
      emit(state.copyWith(
        status: MessageRequestsStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onRefreshed(
    MessageRequestsRefreshed event,
    Emitter<MessageRequestsState> emit,
  ) async {
    emit(state.copyWith(
      status: MessageRequestsStatus.refreshing,
      clearError: true,
    ));
    try {
      final page = await _repo.getMessageRequests(page: 0, size: _pageSize);
      emit(state.copyWith(
        requests: page.content,
        currentPage: 0,
        hasReachedEnd: page.last,
        status: MessageRequestsStatus.success,
        clearError: true,
      ));
    } on ChatException catch (e) {
      emit(state.copyWith(
        status: MessageRequestsStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onLoadMore(
    MessageRequestsLoadMoreRequested event,
    Emitter<MessageRequestsState> emit,
  ) async {
    if (state.hasReachedEnd ||
        state.status == MessageRequestsStatus.loadingMore ||
        state.status == MessageRequestsStatus.loading) {
      return;
    }
    emit(state.copyWith(status: MessageRequestsStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getMessageRequests(
        page: nextPage,
        size: _pageSize,
      );
      emit(state.copyWith(
        requests: [...state.requests, ...page.content],
        currentPage: nextPage,
        hasReachedEnd: page.last,
        status: MessageRequestsStatus.success,
      ));
    } on ChatException catch (e) {
      emit(state.copyWith(
        status: MessageRequestsStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onAccepted(
    MessageRequestAccepted event,
    Emitter<MessageRequestsState> emit,
  ) async {
    if (state.inFlightIds.contains(event.conversationId)) return;
    emit(state.copyWith(
      inFlightIds: {...state.inFlightIds, event.conversationId},
    ));
    try {
      await _repo.acceptRequest(event.conversationId);
      final remaining = state.requests
          .where((c) => c.id != event.conversationId)
          .toList(growable: false);
      emit(state.copyWith(
        requests: remaining,
        inFlightIds: {...state.inFlightIds}..remove(event.conversationId),
      ));
      _inbox.add(InboxRefreshed());
    } on ChatException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
        inFlightIds: {...state.inFlightIds}..remove(event.conversationId),
      ));
    }
  }

  Future<void> _onRejected(
    MessageRequestRejected event,
    Emitter<MessageRequestsState> emit,
  ) async {
    if (state.inFlightIds.contains(event.conversationId)) return;
    emit(state.copyWith(
      inFlightIds: {...state.inFlightIds, event.conversationId},
    ));
    try {
      await _repo.rejectRequest(event.conversationId);
      final remaining = state.requests
          .where((c) => c.id != event.conversationId)
          .toList(growable: false);
      emit(state.copyWith(
        requests: remaining,
        inFlightIds: {...state.inFlightIds}..remove(event.conversationId),
      ));
    } on ChatException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
        inFlightIds: {...state.inFlightIds}..remove(event.conversationId),
      ));
    }
  }
}
