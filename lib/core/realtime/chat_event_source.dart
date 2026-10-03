import 'dart:async';

import 'package:hangout/core/realtime/chat_event.dart';

abstract class ChatEventSource {
  Stream<ChatEvent> get events;

  Stream<bool> get connectedStream;
  bool get isConnected;

  Future<void> connect();
  Future<void> disconnect();

  Future<void> subscribeToConversation(String conversationId);
  Future<void> unsubscribeFromConversation(String conversationId);

  Future<void> subscribeToPresence(String userId);
  Future<void> unsubscribeFromPresence(String userId);

  Future<void> emitTyping(String conversationId, {required bool typing});
}

class NoopChatEventSource implements ChatEventSource {
  final _controller = StreamController<ChatEvent>.broadcast();

  @override
  Stream<ChatEvent> get events => _controller.stream;

  @override
  Stream<bool> get connectedStream => const Stream.empty();

  @override
  bool get isConnected => false;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> subscribeToConversation(String conversationId) async {}

  @override
  Future<void> unsubscribeFromConversation(String conversationId) async {}

  @override
  Future<void> subscribeToPresence(String userId) async {}

  @override
  Future<void> unsubscribeFromPresence(String userId) async {}

  @override
  Future<void> emitTyping(String conversationId, {required bool typing}) async {}
}
