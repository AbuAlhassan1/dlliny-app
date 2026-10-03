import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/core/realtime/chat_event.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/data/local/chat_cache_repository.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/data/repositories/voice_upload_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/send_message_request.dart';
import 'package:hangout/domain/dto/request/update_conversation_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  static const int _pageSize = 50;

  final ChatRepository _repo;
  final VoiceUploadRepository _voiceUpload;
  final ChatInboxBloc _inbox;
  final ChatEventSource _events;
  final ChatCacheRepository _cache;
  final String conversationId;
  final String? viewerId;

  String? _lastReadId;

  late final StreamSubscription<ChatEvent> _wsSub;

  final Map<String, Timer> _typingTimers = {};

  String? _presencePeerId;

  ConversationBloc({
    required ChatRepository repo,
    required VoiceUploadRepository voiceUpload,
    required ChatInboxBloc inbox,
    required ChatEventSource events,
    required ChatCacheRepository cache,
    required this.conversationId,
    required this.viewerId,
  })  : _repo = repo,
        _voiceUpload = voiceUpload,
        _inbox = inbox,
        _events = events,
        _cache = cache,
        super(const ConversationState()) {
    on<ConversationOpened>(_onOpened);
    on<OlderMessagesRequested>(_onOlder);
    on<ConversationRefreshed>(_onRefreshed);
    on<TextMessageSent>(_onTextSent);
    on<VoiceMessageSent>(_onVoiceSent);
    on<MessageRetryRequested>(_onRetry);
    on<ReadMarkerAdvanced>(_onMarkRead);
    on<MessageEditRequested>(_onEdit);
    on<MessageDeleteRequested>(_onDelete);
    on<ConversationMutedRequested>(_onMuteToggled);
    on<ConversationLeaveRequested>(_onLeft);
    on<ConversationSettingsUpdated>(_onSettingsUpdated);
    on<MembersAddRequested>(_onMembersAdded);
    on<MemberRemoveRequested>(_onMemberRemoved);
    on<MemberRoleChangeRequested>(_onMemberRoleChanged);
    on<_WsEventReceived>(_onWs);
    on<_TypingTimedOut>(_onTypingTimedOut);

    _events.subscribeToConversation(conversationId);
    _wsSub = _events.events.listen((e) => add(_WsEventReceived(e)));
  }

  @override
  Future<void> close() async {
    await _wsSub.cancel();
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    _events.unsubscribeFromConversation(conversationId);
    final peer = _presencePeerId;
    if (peer != null) _events.unsubscribeFromPresence(peer);
    return super.close();
  }

  Future<void> _onOpened(
    ConversationOpened event,
    Emitter<ConversationState> emit,
  ) async {
    if (state.status == ConversationStatus.loading) return;

    final cachedConv = await _cache.loadConversation(conversationId);
    final cachedMessages =
        await _cache.loadLatestMessages(conversationId, limit: _pageSize);
    final pending = await _cache.loadPendingFor(conversationId);
    final warmMessages = [
      ...cachedMessages.map((m) => MessageDisplayItem(message: m)),
      ..._pendingToDisplayItems(pending),
    ];
    if (cachedConv != null || warmMessages.isNotEmpty) {
      emit(state.copyWith(
        conversation: cachedConv ?? state.conversation,
        messages: warmMessages,
        status: ConversationStatus.loading,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(
        status: ConversationStatus.loading,
        clearError: true,
      ));
    }

    try {
      final results = await Future.wait([
        _repo.getConversation(conversationId),
        _repo.getMessages(conversationId, page: 0, size: _pageSize),
      ]);
      final conversation = results[0] as ConversationResponse;
      final page = results[1] as PagedResponse<MessageResponse>;
      final fresh = _toSortedDisplay(page.content);
      final stillPending = state.messages
          .where((m) => m.isPending || m.isFailed)
          .toList(growable: false);
      final merged = [...fresh, ...stillPending];
      emit(state.copyWith(
        conversation: conversation,
        messages: merged,
        currentPage: 0,
        hasReachedEnd: page.last,
        status: ConversationStatus.success,
        clearError: true,
      ));
      await _cache.upsertConversation(conversation);
      await _cache.upsertMessages(conversationId, page.content);
      _ensurePresenceSubscription(conversation);
      _maybeMarkLatestRead(merged);
    } on ChatException catch (e) {
      emit(state.copyWith(
        status: ConversationStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  List<MessageDisplayItem> _pendingToDisplayItems(List<PendingSend> pending) {
    if (pending.isEmpty) return const [];
    final out = <MessageDisplayItem>[];
    for (final p in pending) {
      out.add(MessageDisplayItem(
        message: MessageResponse(
          id: p.localId,
          conversationId: p.conversationId,
          senderType: ChatMemberType.user,
          senderId: viewerId ?? '',
          contentType: p.contentType,
          content: p.content,
          audioDurationSeconds: p.audioDurationSeconds,
          audioWaveform: p.audioWaveform,
          replyToMessageId: p.replyToMessageId,
          deletedForEveryone: false,
          createdAt: p.failedAt.toUtc().toIso8601String(),
        ),
        state: MessageDeliveryState.failed,
        localId: p.localId,
        localFilePath: p.audioFilePath,
      ));
    }
    return out;
  }

  Future<void> _onOlder(
    OlderMessagesRequested event,
    Emitter<ConversationState> emit,
  ) async {
    if (state.hasReachedEnd ||
        state.status == ConversationStatus.loadingMore ||
        state.status == ConversationStatus.loading) {
      return;
    }
    emit(state.copyWith(status: ConversationStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getMessages(
        conversationId,
        page: nextPage,
        size: _pageSize,
      );
      final older = _toSortedDisplay(page.content);
      emit(state.copyWith(
        messages: [...older, ...state.messages],
        currentPage: nextPage,
        hasReachedEnd: page.last,
        status: ConversationStatus.success,
      ));
    } on ChatException catch (e) {
      emit(state.copyWith(
        status: ConversationStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onRefreshed(
    ConversationRefreshed event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(
      status: ConversationStatus.refreshing,
      clearError: true,
    ));
    try {
      final results = await Future.wait([
        _repo.getConversation(conversationId),
        _repo.getMessages(conversationId, page: 0, size: _pageSize),
      ]);
      final conversation = results[0] as ConversationResponse;
      final page = results[1] as PagedResponse<MessageResponse>;
      final pending = state.messages
          .where((m) => m.isPending || m.isFailed)
          .toList(growable: false);
      final server = _toSortedDisplay(page.content);
      final merged = [...server, ...pending];
      emit(state.copyWith(
        conversation: conversation,
        messages: merged,
        currentPage: 0,
        hasReachedEnd: page.last,
        status: ConversationStatus.success,
        clearError: true,
      ));
      _maybeMarkLatestRead(merged);
    } on ChatException catch (e) {
      emit(state.copyWith(
        status: ConversationStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onTextSent(
    TextMessageSent event,
    Emitter<ConversationState> emit,
  ) async {
    final trimmed = event.content.trim();
    if (trimmed.isEmpty || viewerId == null) return;

    final localId = _newLocalId();
    final placeholder = _buildPlaceholder(
      localId: localId,
      content: trimmed,
      replyToId: event.replyToId,
    );
    emit(state.copyWith(messages: [...state.messages, placeholder]));

    await _performSend(
      localId: localId,
      request: SendMessageRequest.text(trimmed, replyTo: event.replyToId),
      emit: emit,
    );
  }

  Future<void> _onVoiceSent(
    VoiceMessageSent event,
    Emitter<ConversationState> emit,
  ) async {
    if (viewerId == null) return;
    final localId = _newLocalId();
    final placeholder = MessageDisplayItem(
      message: MessageResponse(
        id: localId,
        conversationId: conversationId,
        senderType: ChatMemberType.user,
        senderId: viewerId ?? '',
        contentType: MessageContentType.voice,
        audioDurationSeconds: event.durationSeconds,
        audioWaveform: event.waveformJson,
        replyToMessageId: event.replyToId,
        deletedForEveryone: false,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      ),
      state: MessageDeliveryState.pending,
      localId: localId,
      localFilePath: event.localFilePath,
    );
    emit(state.copyWith(messages: [...state.messages, placeholder]));

    await _performVoiceSend(
      localId: localId,
      localFilePath: event.localFilePath,
      mimeType: event.mimeType,
      durationSeconds: event.durationSeconds,
      waveformJson: event.waveformJson,
      replyToId: event.replyToId,
      emit: emit,
    );
  }

  Future<void> _onRetry(
    MessageRetryRequested event,
    Emitter<ConversationState> emit,
  ) async {
    final idx = state.messages.indexWhere((m) => m.localId == event.localId);
    if (idx == -1) return;
    final placeholder = state.messages[idx];
    if (!placeholder.isFailed) return;

    final flipped = state.messages.toList()
      ..[idx] = placeholder.copyWith(state: MessageDeliveryState.pending);
    emit(state.copyWith(messages: flipped));

    final m = placeholder.message;
    if (m.contentType == MessageContentType.text && m.content != null) {
      await _performSend(
        localId: event.localId,
        request: SendMessageRequest.text(
          m.content!,
          replyTo: m.replyToMessageId,
        ),
        emit: emit,
      );
      return;
    }
    if (m.contentType == MessageContentType.voice &&
        placeholder.localFilePath != null &&
        m.audioDurationSeconds != null) {
      await _performVoiceSend(
        localId: event.localId,
        localFilePath: placeholder.localFilePath!,
        mimeType: _platformVoiceMime(),
        durationSeconds: m.audioDurationSeconds!,
        waveformJson: m.audioWaveform ?? '[]',
        replyToId: m.replyToMessageId,
        emit: emit,
      );
      return;
    }
    final reverted = state.messages.toList()
      ..[idx] = placeholder.copyWith(state: MessageDeliveryState.failed);
    emit(state.copyWith(messages: reverted));
  }

  Future<void> _performVoiceSend({
    required String localId,
    required String localFilePath,
    required String mimeType,
    required int durationSeconds,
    required String waveformJson,
    required String? replyToId,
    required Emitter<ConversationState> emit,
  }) async {
    try {
      final key = await _voiceUpload.uploadVoice(
        audio: File(localFilePath),
        mimeType: mimeType,
      );
      final server = await _repo.sendMessage(
        conversationId,
        SendMessageRequest.voice(
          audioKey: key,
          audioDurationSeconds: durationSeconds,
          audioWaveform: waveformJson,
          replyTo: replyToId,
        ),
      );
      final wsAlreadyInserted = state.messages.any(
        (m) => m.localId != localId && m.message.id == server.id,
      );
      final List<MessageDisplayItem> next;
      if (wsAlreadyInserted) {
        next = state.messages
            .where((m) => m.localId != localId)
            .toList(growable: false);
      } else {
        next = state.messages.map((m) {
          if (m.localId == localId) {
            return MessageDisplayItem(
              message: server,
              state: MessageDeliveryState.sent,
              localId: localId,
              localFilePath: localFilePath,
            );
          }
          return m;
        }).toList(growable: false);
      }
      emit(state.copyWith(messages: next));
      _bumpInboxAfterSend(server);
    } on ChatException catch (e) {
      final flipped = state.messages.map((m) {
        if (m.localId == localId) {
          return m.copyWith(state: MessageDeliveryState.failed);
        }
        return m;
      }).toList(growable: false);
      emit(state.copyWith(messages: flipped, errorMessage: e.message));
    }
  }

  String _platformVoiceMime() {
    return Platform.isIOS ? 'audio/m4a' : 'audio/aac';
  }

  Future<void> _performSend({
    required String localId,
    required SendMessageRequest request,
    required Emitter<ConversationState> emit,
  }) async {
    try {
      final server = await _repo.sendMessage(conversationId, request);
      final wsAlreadyInserted = state.messages.any(
        (m) => m.localId != localId && m.message.id == server.id,
      );
      final List<MessageDisplayItem> next;
      if (wsAlreadyInserted) {
        next = state.messages
            .where((m) => m.localId != localId)
            .toList(growable: false);
      } else {
        next = state.messages.map((m) {
          if (m.localId == localId) {
            return MessageDisplayItem(
              message: server,
              state: MessageDeliveryState.sent,
              localId: localId,
            );
          }
          return m;
        }).toList(growable: false);
      }
      emit(state.copyWith(messages: next));
      _bumpInboxAfterSend(server);
      await _cache.upsertMessage(conversationId, server);
      await _cache.removePending(localId);
    } on ChatException catch (e) {
      final flipped = state.messages.map((m) {
        if (m.localId == localId) {
          return m.copyWith(state: MessageDeliveryState.failed);
        }
        return m;
      }).toList(growable: false);
      emit(state.copyWith(
        messages: flipped,
        errorMessage: e.message,
      ));
      final placeholder =
          state.messages.firstWhere((m) => m.localId == localId).message;
      await _cache.enqueuePending(PendingSend(
        localId: localId,
        conversationId: conversationId,
        contentType: placeholder.contentType,
        content: placeholder.content,
        audioFilePath: state.messages
            .firstWhere((m) => m.localId == localId)
            .localFilePath,
        audioDurationSeconds: placeholder.audioDurationSeconds,
        audioWaveform: placeholder.audioWaveform,
        replyToMessageId: placeholder.replyToMessageId,
        failedAt: DateTime.now().toUtc(),
      ));
    }
  }

  Future<void> _onEdit(
    MessageEditRequested event,
    Emitter<ConversationState> emit,
  ) async {
    final trimmed = event.newContent.trim();
    if (trimmed.isEmpty) return;

    final idx =
        state.messages.indexWhere((m) => m.message.id == event.messageId);
    if (idx == -1) return;
    final current = state.messages[idx];
    if (current.message.content == trimmed) return;
    if (current.isPending) return;

    try {
      final server = await _repo.editMessage(event.messageId, trimmed);
      final updated = state.messages.toList()
        ..[idx] = MessageDisplayItem(
          message: server,
          state: MessageDeliveryState.sent,
          localId: current.localId,
        );
      emit(state.copyWith(messages: updated));
      await _cache.upsertMessage(conversationId, server);
    } on EditWindowExpiredException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } on ChatException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onDelete(
    MessageDeleteRequested event,
    Emitter<ConversationState> emit,
  ) async {
    final idx =
        state.messages.indexWhere((m) => m.message.id == event.messageId);
    if (idx == -1) return;
    final original = state.messages[idx];
    if (original.isPending) return;

    if (event.scope == 'me') {
      final filtered = [...state.messages]..removeAt(idx);
      emit(state.copyWith(messages: filtered));
    } else {
      final tombstoned = state.messages.toList()
        ..[idx] = MessageDisplayItem(
          message: _tombstone(original.message),
          state: MessageDeliveryState.sent,
          localId: original.localId,
        );
      emit(state.copyWith(messages: tombstoned));
    }

    try {
      await _repo.deleteMessage(event.messageId, scope: event.scope);
      if (event.scope == 'me') {
        await _cache.removeMessage(event.messageId);
      } else {
        await _cache.upsertMessage(
          conversationId,
          _tombstone(original.message),
        );
      }
    } on ChatException catch (e) {
      final restored = [...state.messages];
      if (event.scope == 'me') {
        final stillIdx =
            restored.indexWhere((m) => m.message.id == event.messageId);
        if (stillIdx == -1) {
          restored.add(original);
        }
      } else {
        final tombIdx =
            restored.indexWhere((m) => m.message.id == event.messageId);
        if (tombIdx != -1) {
          restored[tombIdx] = original;
        }
      }
      emit(state.copyWith(messages: restored, errorMessage: e.message));
    }
  }

  MessageResponse _tombstone(MessageResponse m) => MessageResponse(
        id: m.id,
        conversationId: m.conversationId,
        senderType: m.senderType,
        senderId: m.senderId,
        contentType: m.contentType,
        deletedForEveryone: true,
        createdAt: m.createdAt,
      );

  Future<void> _onMuteToggled(
    ConversationMutedRequested event,
    Emitter<ConversationState> emit,
  ) async {
    final c = state.conversation;
    if (c == null) return;
    final wasMuted = c.muted;
    if (wasMuted == event.muted) return;

    emit(state.copyWith(conversation: _withMuted(c, event.muted)));
    try {
      await _repo.setMuted(conversationId, event.muted);
    } on ChatException catch (e) {
      emit(state.copyWith(
        conversation: _withMuted(state.conversation ?? c, wasMuted),
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onLeft(
    ConversationLeaveRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _repo.leaveConversation(conversationId);
      _inbox.add(InboxConversationRemoved(conversationId));
      emit(state.copyWith(isLeft: true));
      await _cache.removeConversation(conversationId);
    } on ChatException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onSettingsUpdated(
    ConversationSettingsUpdated event,
    Emitter<ConversationState> emit,
  ) async {
    final c = state.conversation;
    if (c == null) return;
    try {
      final updated = await _repo.updateConversation(
        conversationId,
        UpdateConversationRequest(
          title: event.title,
          retentionDays: event.clearRetention ? null : event.retentionDays,
        ),
      );
      emit(state.copyWith(conversation: updated));
      _inbox.add(InboxConversationUpdated(updated));
    } on ChatException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onMembersAdded(
    MembersAddRequested event,
    Emitter<ConversationState> emit,
  ) async {
    if (event.userIds.isEmpty) return;
    try {
      final updated = await _repo.addMembers(conversationId, event.userIds);
      emit(state.copyWith(conversation: updated));
      _inbox.add(InboxConversationUpdated(updated));
    } on ChatException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onMemberRemoved(
    MemberRemoveRequested event,
    Emitter<ConversationState> emit,
  ) async {
    final c = state.conversation;
    if (c == null) return;
    final original = c.members;
    final filtered = c.members
        .where((m) => m.memberId != event.userId)
        .toList(growable: false);
    emit(state.copyWith(conversation: _withMembers(c, filtered)));
    try {
      await _repo.removeMember(conversationId, event.userId);
      final fresh = await _repo.getConversation(conversationId);
      emit(state.copyWith(conversation: fresh));
      _inbox.add(InboxConversationUpdated(fresh));
    } on ChatException catch (e) {
      emit(state.copyWith(
        conversation: _withMembers(c, original),
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onMemberRoleChanged(
    MemberRoleChangeRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _repo.updateMemberRole(
        conversationId,
        event.userId,
        event.promoteToAdmin
            ? ChatMemberRole.admin
            : ChatMemberRole.member,
      );
      final fresh = await _repo.getConversation(conversationId);
      emit(state.copyWith(conversation: fresh));
      _inbox.add(InboxConversationUpdated(fresh));
    } on ChatException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  ConversationResponse _withMuted(ConversationResponse c, bool muted) =>
      ConversationResponse(
        id: c.id,
        type: c.type,
        title: c.title,
        avatarUrl: c.avatarUrl,
        members: c.members,
        lastMessage: c.lastMessage,
        unreadCount: c.unreadCount,
        viewerRequestState: c.viewerRequestState,
        muted: muted,
        retentionDays: c.retentionDays,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  void _onWs(_WsEventReceived event, Emitter<ConversationState> emit) {
    final ev = event.event;
    if (ev is PresenceChanged) {
      if (ev.userId != _presencePeerId) return;
      emit(state.copyWith(
        peerOnline: ev.online,
        peerLastSeenAt: ev.lastSeenAt ?? state.peerLastSeenAt,
      ));
      return;
    }
    if (ev.conversationId != conversationId) return;

    if (ev is MessageCreated) {
      _applyIncomingMessage(ev.message, emit);
    } else if (ev is MessageEdited) {
      _replaceMessage(ev.message, emit);
    } else if (ev is MessageDeleted) {
      _tombstoneMessage(ev.messageId, emit);
    } else if (ev is ReadReceiptReceived) {
      if (ev.memberId == viewerId) return;
      if (state.conversation?.type == ConversationType.direct) {
        emit(state.copyWith(peerReadMessageId: ev.upToMessageId));
      }
    } else if (ev is TypingChanged) {
      _handleTyping(ev, emit);
    } else if (ev is RequestAcceptedRemotely) {
      add(ConversationRefreshed());
    } else if (ev is ConversationUpdatedRemotely) {
      emit(state.copyWith(conversation: ev.conversation));
    } else if (ev is MemberAdded ||
        ev is MemberRemoved ||
        ev is MemberRoleChanged) {
      add(ConversationRefreshed());
    }
  }

  void _applyIncomingMessage(
    MessageResponse message,
    Emitter<ConversationState> emit,
  ) {
    if (state.messages.any((m) => m.message.id == message.id)) return;
    final updated = [
      ...state.messages,
      MessageDisplayItem(message: message),
    ];
    emit(state.copyWith(messages: updated));
    _cache.upsertMessage(conversationId, message);
    _maybeMarkLatestRead(updated);
  }

  void _replaceMessage(
    MessageResponse message,
    Emitter<ConversationState> emit,
  ) {
    final idx =
        state.messages.indexWhere((m) => m.message.id == message.id);
    if (idx == -1) return;
    final updated = state.messages.toList()
      ..[idx] = state.messages[idx].copyWith(message: message);
    emit(state.copyWith(messages: updated));
    _cache.upsertMessage(conversationId, message);
  }

  void _tombstoneMessage(
    String messageId,
    Emitter<ConversationState> emit,
  ) {
    final idx =
        state.messages.indexWhere((m) => m.message.id == messageId);
    if (idx == -1) return;
    final original = state.messages[idx];
    final tomb = _tombstone(original.message);
    final updated = state.messages.toList()
      ..[idx] = original.copyWith(message: tomb);
    emit(state.copyWith(messages: updated));
    _cache.upsertMessage(conversationId, tomb);
  }

  void _handleTyping(
    TypingChanged ev,
    Emitter<ConversationState> emit,
  ) {
    if (ev.memberId == viewerId) return;
    final next = Map<String, DateTime>.from(state.typingByMember);
    _typingTimers[ev.memberId]?.cancel();
    if (ev.typing) {
      next[ev.memberId] = DateTime.now();
      _typingTimers[ev.memberId] = Timer(
        const Duration(seconds: 5),
        () => add(_TypingTimedOut(ev.memberId)),
      );
    } else {
      next.remove(ev.memberId);
      _typingTimers.remove(ev.memberId);
    }
    emit(state.copyWith(typingByMember: next));
  }

  void _onTypingTimedOut(
    _TypingTimedOut event,
    Emitter<ConversationState> emit,
  ) {
    if (!state.typingByMember.containsKey(event.memberId)) return;
    final next = Map<String, DateTime>.from(state.typingByMember)
      ..remove(event.memberId);
    _typingTimers.remove(event.memberId);
    emit(state.copyWith(typingByMember: next));
  }

  void _ensurePresenceSubscription(ConversationResponse c) {
    if (c.type != ConversationType.direct) return;
    String? peer;
    for (final m in c.members) {
      if (m.memberType == ChatMemberType.user && m.memberId != viewerId) {
        peer = m.memberId;
        break;
      }
    }
    if (peer == null || peer == _presencePeerId) return;
    if (_presencePeerId != null) {
      _events.unsubscribeFromPresence(_presencePeerId!);
    }
    _presencePeerId = peer;
    _events.subscribeToPresence(peer);
  }

  ConversationResponse _withMembers(
    ConversationResponse c,
    List<ChatMemberResponse> members,
  ) =>
      ConversationResponse(
        id: c.id,
        type: c.type,
        title: c.title,
        avatarUrl: c.avatarUrl,
        members: members,
        lastMessage: c.lastMessage,
        unreadCount: c.unreadCount,
        viewerRequestState: c.viewerRequestState,
        muted: c.muted,
        retentionDays: c.retentionDays,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  Future<void> _onMarkRead(
    ReadMarkerAdvanced event,
    Emitter<ConversationState> emit,
  ) async {
    if (event.messageId == _lastReadId) return;
    _lastReadId = event.messageId;
    try {
      await _repo.markRead(conversationId, event.messageId);
      final c = state.conversation;
      if (c != null && c.unreadCount != 0) {
        emit(state.copyWith(conversation: _withUnread(c, 0)));
      }
    } on ChatException {
      _lastReadId = null;
    }
  }

  void _maybeMarkLatestRead(List<MessageDisplayItem> sortedOldestFirst) {
    if (sortedOldestFirst.isEmpty) return;
    for (var i = sortedOldestFirst.length - 1; i >= 0; i--) {
      final item = sortedOldestFirst[i];
      if (!item.isPending) {
        add(ReadMarkerAdvanced(item.message.id));
        return;
      }
    }
  }

  void _bumpInboxAfterSend(MessageResponse server) {
    final c = state.conversation;
    if (c == null) return;
    final patched = ConversationResponse(
      id: c.id,
      type: c.type,
      title: c.title,
      avatarUrl: c.avatarUrl,
      members: c.members,
      lastMessage: server,
      unreadCount: 0,
      viewerRequestState: c.viewerRequestState,
      muted: c.muted,
      retentionDays: c.retentionDays,
      createdAt: c.createdAt,
      updatedAt: server.createdAt,
    );
    _inbox.add(InboxConversationUpdated(patched));
  }

  ConversationResponse _withUnread(ConversationResponse c, int unread) {
    return ConversationResponse(
      id: c.id,
      type: c.type,
      title: c.title,
      avatarUrl: c.avatarUrl,
      members: c.members,
      lastMessage: c.lastMessage,
      unreadCount: unread,
      viewerRequestState: c.viewerRequestState,
      muted: c.muted,
      retentionDays: c.retentionDays,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  MessageDisplayItem _buildPlaceholder({
    required String localId,
    required String content,
    String? replyToId,
  }) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    return MessageDisplayItem(
      message: MessageResponse(
        id: localId,
        conversationId: conversationId,
        senderType: ChatMemberType.user,
        senderId: viewerId ?? '',
        contentType: MessageContentType.text,
        content: content,
        replyToMessageId: replyToId,
        deletedForEveryone: false,
        createdAt: nowIso,
      ),
      state: MessageDeliveryState.pending,
      localId: localId,
    );
  }

  List<MessageDisplayItem> _toSortedDisplay(List<MessageResponse> page) {
    final sorted = [...page]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted
        .map((m) => MessageDisplayItem(message: m))
        .toList(growable: false);
  }

  String _newLocalId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    return 'local-$micros-${micros.hashCode & 0xffff}';
  }
}
