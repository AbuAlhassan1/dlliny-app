import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/bloc/conversation/conversation_bloc.dart';
import 'package:hangout/presentation/chat/helpers/message_snippet.dart';
import 'package:hangout/presentation/chat/helpers/open_share_sheet.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';
import 'package:hangout/presentation/chat/widgets/edit_message_sheet.dart';
import 'package:hangout/presentation/chat/widgets/message_action_sheet.dart';
import 'package:hangout/presentation/chat/widgets/message_bubble.dart';

class ConversationMessageList extends StatefulWidget {
  final String? viewerId;
  final void Function(MessageDisplayItem item) onReply;

  const ConversationMessageList({
    super.key,
    required this.viewerId,
    required this.onReply,
  });

  @override
  State<ConversationMessageList> createState() =>
      _ConversationMessageListState();
}

class _ConversationMessageListState extends State<ConversationMessageList> {
  final ScrollController _scroll = ScrollController();

  final Map<String, GlobalKey> _bubbleKeys = {};

  String? _highlightedId;

  String? _lastSeenLatestId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadOlder);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadOlder() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<ConversationBloc>().add(OlderMessagesRequested());
    }
  }

  bool _isNearBottom() {
    if (!_scroll.hasClients) return true;
    return _scroll.position.pixels < 80;
  }

  void _autoScrollToBottomIfAppropriate() {
    if (!_scroll.hasClients) return;
    if (_isNearBottom()) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  GlobalKey _keyFor(String messageId) =>
      _bubbleKeys.putIfAbsent(messageId, () => GlobalKey());

  Future<void> _scrollToMessage(String messageId) async {
    final key = _bubbleKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
    setState(() => _highlightedId = messageId);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted && _highlightedId == messageId) {
      setState(() => _highlightedId = null);
    }
  }

  ReplyPreview? _buildReplyPreview(
    ConversationState state,
    MessageDisplayItem item,
  ) {
    final originalId = item.message.replyToMessageId;
    if (originalId == null) return null;
    MessageDisplayItem? original;
    for (final m in state.messages) {
      if (m.message.id == originalId) {
        original = m;
        break;
      }
    }
    if (original == null) {
      return ReplyPreview(
        originalMessageId: originalId,
        isOutOfWindow: true,
      );
    }
    return ReplyPreview(
      originalMessageId: originalId,
      senderDisplayName: _senderDisplayName(
        state.conversation,
        original.message.senderId,
      ),
      snippet: messageSnippet(original),
    );
  }

  Future<void> _handleLongPress(
    MessageDisplayItem item,
    bool isMine,
  ) async {
    HapticFeedback.lightImpact();
    final action = await showMessageActionSheet(
      context,
      item: item,
      isMine: isMine,
    );
    if (action == null || !mounted) return;
    final bloc = context.read<ConversationBloc>();
    switch (action) {
      case MessageAction.reply:
        widget.onReply(item);
        break;
      case MessageAction.copy:
        final text = item.message.content ?? '';
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        appToast.success(LocaleKeys.chat_message_copied_toast.tr());
        break;
      case MessageAction.edit:
        final updated = await showEditMessageSheet(
          context,
          initialContent: item.message.content ?? '',
        );
        if (updated == null || !mounted) return;
        bloc.add(MessageEditRequested(item.message.id, updated));
        break;
      case MessageAction.forward:
        final preview = item.message.sharedResource;
        if (preview == null) return;
        await openShareSheet(
          context,
          resourceType: preview.type,
          resourceId: preview.id,
          headlineLabel: LocaleKeys.chat_message_resend_share_headline.tr(),
        );
        break;
      case MessageAction.unsend:
        bloc.add(
          MessageDeleteRequested(item.message.id, scope: 'everyone'),
        );
        break;
      case MessageAction.deleteForMe:
        bloc.add(
          MessageDeleteRequested(item.message.id, scope: 'me'),
        );
        break;
    }
  }

  void _retry(MessageDisplayItem item) {
    final id = item.localId;
    if (id == null) return;
    context.read<ConversationBloc>().add(MessageRetryRequested(id));
  }

  bool _isSeenByPeer(ConversationState state, int index) {
    final lastReadId = state.peerReadMessageId;
    if (lastReadId == null) return false;
    if (state.conversation?.type != ConversationType.direct) return false;
    final readIdx =
        state.messages.indexWhere((m) => m.message.id == lastReadId);
    if (readIdx == -1) return false;
    return index <= readIdx;
  }

  String? _senderDisplayName(
    ConversationResponse? conversation,
    String senderId,
  ) {
    if (conversation == null) return null;
    for (final m in conversation.members) {
      if (m.memberId == senderId) return m.displayName;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocConsumer<ConversationBloc, ConversationState>(
      listenWhen: (p, curr) {
        final newLatestId =
            curr.messages.isNotEmpty ? curr.messages.last.message.id : null;
        return newLatestId != _lastSeenLatestId;
      },
      listener: (context, state) {
        final newLatestId =
            state.messages.isNotEmpty ? state.messages.last.message.id : null;
        if (newLatestId != _lastSeenLatestId) {
          _lastSeenLatestId = newLatestId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoScrollToBottomIfAppropriate();
          });
        }
      },
      builder: (context, state) {
        final isGroup = state.conversation?.type == ConversationType.group;
        return RefreshIndicator(
          onRefresh: () async {
            context.read<ConversationBloc>().add(ConversationRefreshed());
          },
          color: c.onSurface,
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.messages.length) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: c.onSurface,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
                );
              }
              final messageIndex = state.messages.length - 1 - index;
              final item = state.messages[messageIndex];
              final senderId = item.message.senderId;
              final isMine =
                  widget.viewerId != null && senderId == widget.viewerId;
              final previous = messageIndex > 0
                  ? state.messages[messageIndex - 1]
                  : null;
              final showSenderName = isGroup &&
                  !isMine &&
                  (previous == null ||
                      previous.message.senderId != senderId);
              final senderName = showSenderName
                  ? _senderDisplayName(state.conversation, senderId)
                  : null;
              final replyPreview = _buildReplyPreview(state, item);
              final isHighlighted = _highlightedId == item.message.id;
              final isSeenByPeer =
                  isMine && _isSeenByPeer(state, messageIndex);
              return AnimatedContainer(
                key: _keyFor(item.message.id),
                duration: const Duration(milliseconds: 300),
                color: isHighlighted
                    ? c.onSurface.withValues(alpha: 0.06)
                    : Colors.transparent,
                child: GestureDetector(
                  onTap: item.isFailed ? () => _retry(item) : null,
                  onLongPress: () => _handleLongPress(item, isMine),
                  behavior: HitTestBehavior.opaque,
                  child: MessageBubble(
                    item: item,
                    isMine: isMine,
                    senderDisplayName: senderName,
                    showSenderName: showSenderName,
                    replyPreview: replyPreview,
                    isSeenByPeer: isSeenByPeer,
                    onReplyTap: replyPreview == null
                        ? null
                        : () =>
                            _scrollToMessage(replyPreview.originalMessageId),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
