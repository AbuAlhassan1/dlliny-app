class ActiveConversationTracker {
  ActiveConversationTracker._();
  static final ActiveConversationTracker instance =
      ActiveConversationTracker._();

  String? _conversationId;

  String? get conversationId => _conversationId;

  void enter(String id) {
    _conversationId = id;
  }

  void exit(String id) {
    if (_conversationId == id) _conversationId = null;
  }
}
