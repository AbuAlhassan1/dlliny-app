import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/bloc/conversation/conversation_bloc.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';
import 'package:hangout/presentation/chat/widgets/voice_recorder.dart';

class ConversationComposer extends StatefulWidget {
  final MessageDisplayItem? replyTo;

  final String? replyPreviewSnippet;

  final VoidCallback? onClearReply;

  const ConversationComposer({
    super.key,
    this.replyTo,
    this.replyPreviewSnippet,
    this.onClearReply,
  });

  @override
  State<ConversationComposer> createState() => _ConversationComposerState();
}

class _ConversationComposerState extends State<ConversationComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  late final ChatEventSource _wsEvents =
      serviceLocator.get<ChatEventSource>();

  String? _conversationId;

  bool _hasText = false;

  bool _typingEmitted = false;

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focus.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conversationId ??= context.read<ConversationBloc>().conversationId;
  }

  @override
  void didUpdateWidget(covariant ConversationComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyTo != null && oldWidget.replyTo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    final convId = _conversationId;
    if (_typingEmitted && convId != null) {
      _wsEvents.emitTyping(convId, typing: false);
    }
    _controller.removeListener(_onChanged);
    _focus.removeListener(_onFocusChange);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);

    final convId = _conversationId;
    if (convId == null) return;
    if (has) {
      if (!_typingEmitted) {
        _typingEmitted = true;
        _wsEvents.emitTyping(convId, typing: true);
      }
      _idleTimer?.cancel();
      _idleTimer = Timer(const Duration(seconds: 3), _emitStoppedTyping);
    } else if (_typingEmitted) {
      _emitStoppedTyping();
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _typingEmitted) _emitStoppedTyping();
  }

  void _emitStoppedTyping() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (!_typingEmitted) return;
    _typingEmitted = false;
    final convId = _conversationId;
    if (convId == null) return;
    _wsEvents.emitTyping(convId, typing: false);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    context.read<ConversationBloc>().add(
          TextMessageSent(text, replyToId: widget.replyTo?.message.id),
        );
    _controller.clear();
    _emitStoppedTyping();
    widget.onClearReply?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          border: Border(
            top: BorderSide(
              color: c.border,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyTo != null)
              _ReplyChip(
                snippet: widget.replyPreviewSnippet,
                onClear: widget.onClearReply,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: null,
                  icon: Icon(
                    TablerIcons.plus,
                    color: c.onSurfaceDisabled,
                  ),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: c.border,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      cursorColor: c.onSurface,
                      style: TextStyle(color: c.onSurface, fontSize: 15),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: LocaleKeys.chat_composer_hint.tr(),
                        hintStyle: TextStyle(color: c.onSurfaceMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _SendOrMicButton(
                  hasText: _hasText,
                  onSend: _send,
                  replyTo: widget.replyTo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SendOrMicButton extends StatelessWidget {
  final bool hasText;
  final VoidCallback onSend;
  final MessageDisplayItem? replyTo;
  const _SendOrMicButton({
    required this.hasText,
    required this.onSend,
    this.replyTo,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (hasText) {
      return Material(
        color: c.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onSend,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              TablerIcons.send,
              color: c.onPrimary,
              size: 18,
            ),
          ),
        ),
      );
    }
    return VoiceRecorderButton(replyTo: replyTo);
  }
}

class _ReplyChip extends StatelessWidget {
  final String? snippet;
  final VoidCallback? onClear;
  const _ReplyChip({this.snippet, this.onClear});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: c.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.corner_up_left,
            color: c.onSurfaceSecondary,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.chat_composer_replying_to.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (snippet != null && snippet!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    snippet!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClear != null)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  TablerIcons.x,
                  color: c.onSurfaceSecondary,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
