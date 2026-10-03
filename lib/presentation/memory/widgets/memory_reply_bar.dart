import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/request/create_conversation_request.dart';
import 'package:hangout/domain/dto/request/send_message_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/bloc/memory_viewer/memory_viewer_bloc.dart';

class MemoryReplyBar extends StatelessWidget {
  final MemoryResponse memory;
  final MemoryOwnerSummary owner;

  const MemoryReplyBar({
    super.key,
    required this.memory,
    required this.owner,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReactionsRow(memory: memory),
              const SizedBox(height: 10),
              _ReplyComposer(memory: memory, owner: owner),
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> _allowedEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

class _ReactionsRow extends StatefulWidget {
  final MemoryResponse memory;
  const _ReactionsRow({required this.memory});

  @override
  State<_ReactionsRow> createState() => _ReactionsRowState();
}

class _ReactionsRowState extends State<_ReactionsRow> {
  late final MemoryRepository _repo = serviceLocator.get<MemoryRepository>();

  Future<void> _onTap(String emoji) async {
    HapticFeedback.selectionClick();
    final viewer = context.read<MemoryViewerBloc>();
    final memoryId = widget.memory.id;
    final previousActive = viewer.state.effectiveMyEmojiFor(widget.memory);
    final shouldRemove = previousActive == emoji;
    final next = shouldRemove ? null : emoji;

    viewer.add(ReactionOverrideSet(memoryId: memoryId, emoji: next));

    try {
      if (shouldRemove) {
        await _repo.removeReaction(memoryId);
      } else {
        await _repo.react(memoryId, emoji);
      }
    } on MemoryException catch (e) {
      if (!mounted) return;
      viewer.add(
        ReactionOverrideSet(memoryId: memoryId, emoji: previousActive),
      );
      appToast.error(e.message);
      if (e is MemoryExpiredException) {
        viewer.add(MemoryDeletedLocally(memoryId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemoryViewerBloc, MemoryViewerState>(
      buildWhen: (prev, curr) =>
          prev.reactionOverrides[widget.memory.id] !=
          curr.reactionOverrides[widget.memory.id],
      builder: (context, state) {
        final c = context.c;
        final active = state.effectiveMyEmojiFor(widget.memory);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: c.scrimSubtle,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final emoji in _allowedEmojis)
                _EmojiButton(
                  emoji: emoji,
                  selected: emoji == active,
                  onTap: () => _onTap(emoji),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? c.onMediaSurface.withValues(alpha: 0.18)
                : Colors.transparent,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _ReplyComposer extends StatefulWidget {
  final MemoryResponse memory;
  final MemoryOwnerSummary owner;

  const _ReplyComposer({required this.memory, required this.owner});

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<_ReplyComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  late final ChatRepository _chat = serviceLocator.get<ChatRepository>();

  bool _hasText = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focus.removeListener(_onFocusChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    context
        .read<MemoryViewerBloc>()
        .add(PausedToggled(paused: _focus.hasFocus));
  }

  ChatMemberType _peerType(MemoryOwnerType type) {
    switch (type) {
      case MemoryOwnerType.user:
        return ChatMemberType.user;
      case MemoryOwnerType.venue:
        return ChatMemberType.venue;
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.selectionClick();

    try {
      final conversation = await _chat.createConversation(
        CreateConversationRequest(
          type: ConversationType.direct,
          participants: [
            Participant(
              type: _peerType(widget.owner.type),
              id: widget.owner.id,
            ),
          ],
        ),
      );
      await _chat.sendMessage(
        conversation.id,
        SendMessageRequest.share(
          resourceType: SharedResourceType.memory,
          resourceId: widget.memory.id,
          caption: text,
        ),
      );
      if (!mounted) return;
      _controller.clear();
      _focus.unfocus();
      appToast.success('تم الإرسال');
    } on ChatException catch (e) {
      if (!mounted) return;
      appToast.error(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hint = 'الرد على ${widget.owner.displayName ?? ''}…';
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: c.onMediaSurface.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              cursorColor: c.onMediaSurface,
              style: TextStyle(color: c.onMediaSurface, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: c.onMediaSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SendButton(
          enabled: _hasText && !_sending,
          isBusy: _sending,
          onTap: _send,
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool isBusy;
  final VoidCallback onTap;
  const _SendButton({
    required this.enabled,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = enabled
        ? c.onMediaSurface
        : c.onMediaSurface.withValues(alpha: 0.38);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 28,
        height: 28,
        child: isBusy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.onMediaSurface,
                ),
              )
            : Icon(TablerIcons.send, color: color, size: 26),
      ),
    );
  }
}
