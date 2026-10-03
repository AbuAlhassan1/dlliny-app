import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:hangout/core/realtime/chat_event.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class StompChatEventSource implements ChatEventSource {
  static const Duration _heartbeat = Duration(seconds: 10);

  final String wsUrl;
  StompChatEventSource({this.wsUrl = 'wss://api.dlliny.com/ws'});

  final StreamController<ChatEvent> _events =
      StreamController<ChatEvent>.broadcast();
  final StreamController<bool> _connected =
      StreamController<bool>.broadcast();

  StompClient? _client;
  String? _jwt;
  String? _userId;
  bool _isConnected = false;

  final Map<String, _Sub> _pendingSubs = {};
  final Map<String, _Sub> _activeSubs = {};

  @override
  Stream<ChatEvent> get events => _events.stream;

  @override
  Stream<bool> get connectedStream => _connected.stream;

  @override
  bool get isConnected => _isConnected;

  Future<void> setSession({
    required String jwt,
    required String userId,
  }) async {
    if (_jwt == jwt && _userId == userId && _client != null) return;
    await disconnect();
    _jwt = jwt;
    _userId = userId;
    _pendingSubs[_inboxTopicFor(userId)] = _Sub(
      destination: _inboxTopicFor(userId),
      onFrame: _onInboxFrame,
    );
    await connect();
  }

  @override
  Future<void> connect() async {
    final jwt = _jwt;
    if (jwt == null) return;
    if (_client != null) return;

    final client = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $jwt'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $jwt'},
        heartbeatOutgoing: _heartbeat,
        heartbeatIncoming: _heartbeat,
        reconnectDelay: const Duration(seconds: 5),
        onConnect: _onConnect,
        onWebSocketError: (e) => log('STOMP ws error: $e'),
        onStompError: (f) => log('STOMP frame error: ${f.body}'),
        onDisconnect: (_) => _onDisconnect(),
        onWebSocketDone: _onDisconnect,
      ),
    );
    _client = client;
    client.activate();
  }

  void _onConnect(StompFrame _) {
    log('STOMP connected. Re-applying ${_pendingSubs.length} subscription(s).');
    _isConnected = true;
    if (!_connected.isClosed) _connected.add(true);
    for (final entry in _pendingSubs.entries) {
      _applySubscription(entry.value);
    }
  }

  void _onDisconnect() {
    log('STOMP disconnected.');
    _isConnected = false;
    if (!_connected.isClosed) _connected.add(false);
    _activeSubs.clear();
  }

  @override
  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    _pendingSubs.clear();
    _activeSubs.clear();
    _isConnected = false;
    if (!_connected.isClosed) _connected.add(false);
    if (client != null) {
      try {
        client.deactivate();
      } catch (e) {
        log('STOMP deactivate threw: $e');
      }
    }
  }

  @override
  Future<void> subscribeToConversation(String conversationId) async {
    final dest = '/topic/conversations/$conversationId';
    if (_pendingSubs.containsKey(dest)) return;
    final sub = _Sub(
      destination: dest,
      onFrame: (frame) => _onConversationFrame(conversationId, frame),
    );
    _pendingSubs[dest] = sub;
    if (_isConnected) _applySubscription(sub);
  }

  @override
  Future<void> unsubscribeFromConversation(String conversationId) async {
    final dest = '/topic/conversations/$conversationId';
    _pendingSubs.remove(dest);
    final active = _activeSubs.remove(dest);
    active?.unsubscribe?.call(unsubscribeHeaders: {});
  }

  @override
  Future<void> subscribeToPresence(String userId) async {
    final dest = '/topic/users/$userId/presence';
    if (_pendingSubs.containsKey(dest)) return;
    final sub = _Sub(
      destination: dest,
      onFrame: (frame) => _onPresenceFrame(userId, frame),
    );
    _pendingSubs[dest] = sub;
    if (_isConnected) _applySubscription(sub);
  }

  @override
  Future<void> unsubscribeFromPresence(String userId) async {
    final dest = '/topic/users/$userId/presence';
    _pendingSubs.remove(dest);
    final active = _activeSubs.remove(dest);
    active?.unsubscribe?.call(unsubscribeHeaders: {});
  }

  @override
  Future<void> emitTyping(
    String conversationId, {
    required bool typing,
  }) async {
    final client = _client;
    final clientReady = client != null;
    log('STOMP typing attempt: typing=$typing conv=$conversationId '
        'clientExists=$clientReady connected=$_isConnected');
    if (client == null || !_isConnected) return;
    try {
      final body = typing ? 'true' : 'false';
      log('STOMP TYPING out → conv=$conversationId body=$body');
      client.send(
        destination: '/app/conversations/$conversationId/typing',
        body: body,
        headers: const {'content-type': 'application/json'},
      );
    } catch (e) {
      log('STOMP typing emit failed: $e');
    }
  }

  String _inboxTopicFor(String userId) => '/topic/users/$userId/inbox';

  void _applySubscription(_Sub sub) {
    final client = _client;
    if (client == null) return;
    try {
      final unsub = client.subscribe(
        destination: sub.destination,
        callback: sub.onFrame,
      );
      sub.unsubscribe = unsub;
      _activeSubs[sub.destination] = sub;
    } catch (e) {
      log('STOMP subscribe failed for ${sub.destination}: $e');
    }
  }

  void _onInboxFrame(StompFrame frame) {
    final payload = _decode(frame.body);
    if (payload == null) return;
    final convoId = payload['conversationId'] as String?;
    if (convoId == null) return;
    final landedRaw = (payload['landedIn'] as String?)?.toUpperCase();
    final landedIn = landedRaw == 'PENDING'
        ? ChatRequestState.pending
        : ChatRequestState.accepted;
    _emit(InboxRefreshHint(convoId, landedIn));
  }

  void _onConversationFrame(String conversationId, StompFrame frame) {
    log('STOMP frame conv=$conversationId body=${frame.body}');
    final payload = _decode(frame.body);
    if (payload == null) return;
    final type = (payload['type'] as String?)?.toUpperCase();
    switch (type) {
      case 'MESSAGE_CREATED':
        final msg = _parseMessage(payload['message']);
        if (msg != null) _emit(MessageCreated(conversationId, msg));
        break;
      case 'MESSAGE_EDITED':
        final msg = _parseMessage(payload['message']);
        if (msg != null) _emit(MessageEdited(conversationId, msg));
        break;
      case 'MESSAGE_DELETED':
        final msg = _parseMessage(payload['message']);
        final id = msg?.id ?? (payload['messageId'] as String?);
        if (id != null) _emit(MessageDeleted(conversationId, id));
        break;
      case 'READ_RECEIPT':
        final wrapper = payload['readReceipt'];
        if (wrapper is! Map<String, dynamic>) break;
        final memberId = (wrapper['userId'] as String?) ??
            (wrapper['memberId'] as String?);
        final memberType = _parseMemberType(wrapper['memberType']) ??
            ChatMemberType.user;
        final upTo = (wrapper['messageId'] as String?) ??
            (wrapper['upToMessageId'] as String?);
        if (memberId != null && upTo != null) {
          _emit(ReadReceiptReceived(
            conversationId,
            memberId: memberId,
            memberType: memberType,
            upToMessageId: upTo,
          ));
        }
        break;
      case 'TYPING':
        final wrapper = payload['typing'];
        if (wrapper is! Map<String, dynamic>) {
          log('STOMP TYPING dropped — typing wrapper not an object: $wrapper');
          break;
        }
        final memberId = (wrapper['userId'] as String?) ??
            (wrapper['memberId'] as String?) ??
            (wrapper['senderId'] as String?);
        final memberType = _parseMemberType(
              wrapper['memberType'] ?? wrapper['senderType'],
            ) ??
            ChatMemberType.user;
        final typingRaw = wrapper['typing'] ?? wrapper['isTyping'];
        final typing = typingRaw is bool ? typingRaw : null;
        if (memberId != null && typing != null) {
          _emit(TypingChanged(
            conversationId,
            memberId: memberId,
            memberType: memberType,
            typing: typing,
          ));
        } else {
          log('STOMP TYPING dropped — memberId=$memberId typing=$typingRaw '
              'wrapper=$wrapper');
        }
        break;
      case 'REQUEST_ACCEPTED':
        _emit(RequestAcceptedRemotely(conversationId));
        break;
      case 'MEMBER_ADDED':
      case 'MEMBER_REMOVED':
      case 'MEMBER_ROLE_CHANGED':
        _handleMemberChange(conversationId, type!, payload['memberChange']);
        break;
      case 'CONVERSATION_UPDATED':
        final c = _parseConversation(payload['conversation']);
        if (c != null) _emit(ConversationUpdatedRemotely(conversationId, c));
        break;
    }
  }

  void _handleMemberChange(
    String conversationId,
    String type,
    dynamic raw,
  ) {
    if (raw is! Map<String, dynamic>) return;
    switch (type) {
      case 'MEMBER_ADDED':
        final members =
            _parseMembers(raw['members'] ?? raw['added']);
        if (members != null) _emit(MemberAdded(conversationId, members));
        break;
      case 'MEMBER_REMOVED':
        final memberId = (raw['userId'] as String?) ??
            (raw['memberId'] as String?);
        final memberType =
            _parseMemberType(raw['memberType']) ?? ChatMemberType.user;
        if (memberId != null) {
          _emit(MemberRemoved(
            conversationId,
            memberId: memberId,
            memberType: memberType,
          ));
        }
        break;
      case 'MEMBER_ROLE_CHANGED':
        final memberId = (raw['userId'] as String?) ??
            (raw['memberId'] as String?);
        final memberType =
            _parseMemberType(raw['memberType']) ?? ChatMemberType.user;
        final roleRaw = (raw['role'] as String?)?.toUpperCase();
        final role = roleRaw == 'ADMIN'
            ? ChatMemberRole.admin
            : ChatMemberRole.member;
        if (memberId != null) {
          _emit(MemberRoleChanged(
            conversationId,
            memberId: memberId,
            memberType: memberType,
            role: role,
          ));
        }
        break;
    }
  }

  void _onPresenceFrame(String userId, StompFrame frame) {
    final payload = _decode(frame.body);
    if (payload == null) return;
    final online = payload['online'];
    if (online is! bool) return;
    _emit(PresenceChanged(
      userId: userId,
      online: online,
      lastSeenAt: _normaliseTimestamp(payload['lastSeenAt']),
    ));
  }

  String? _normaliseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true)
          .toIso8601String();
    }
    return null;
  }

  Map<String, dynamic>? _decode(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final raw = jsonDecode(body);
      if (raw is Map<String, dynamic>) return raw;
      return null;
    } catch (e) {
      log('STOMP body decode failed: $e — body=$body');
      return null;
    }
  }

  ChatMemberType? _parseMemberType(dynamic raw) {
    if (raw is! String) return null;
    switch (raw.toUpperCase()) {
      case 'USER':
        return ChatMemberType.user;
      case 'VENUE':
        return ChatMemberType.venue;
    }
    return null;
  }

  MessageResponse? _parseMessage(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      return MessageResponse.fromJson(raw);
    } catch (e) {
      log('STOMP message parse failed: $e');
      return null;
    }
  }

  ConversationResponse? _parseConversation(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      return ConversationResponse.fromJson(raw);
    } catch (e) {
      log('STOMP conversation parse failed: $e');
      return null;
    }
  }

  List<ChatMemberResponse>? _parseMembers(dynamic raw) {
    if (raw is! List) return null;
    try {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ChatMemberResponse.fromJson)
          .toList(growable: false);
    } catch (e) {
      log('STOMP members parse failed: $e');
      return null;
    }
  }

  void _emit(ChatEvent event) {
    if (_events.isClosed) return;
    _events.add(event);
  }
}

class _Sub {
  final String destination;
  final void Function(StompFrame frame) onFrame;
  void Function({Map<String, String> unsubscribeHeaders})? unsubscribe;
  _Sub({required this.destination, required this.onFrame});
}
