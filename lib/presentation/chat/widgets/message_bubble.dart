import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';
import 'package:hangout/presentation/chat/widgets/relative_time.dart';
import 'package:hangout/presentation/chat/widgets/share_message_content.dart';
import 'package:hangout/presentation/chat/widgets/voice_message_content.dart';

class ReplyPreview {
  final String originalMessageId;
  final String? senderDisplayName;
  final String? snippet;

  final bool isOutOfWindow;

  const ReplyPreview({
    required this.originalMessageId,
    this.senderDisplayName,
    this.snippet,
    this.isOutOfWindow = false,
  });
}

class MessageBubble extends StatelessWidget {
  final MessageDisplayItem item;

  final bool isMine;

  final String? senderDisplayName;

  final bool showSenderName;

  final ReplyPreview? replyPreview;

  final VoidCallback? onReplyTap;

  final bool isSeenByPeer;

  const MessageBubble({
    super.key,
    required this.item,
    required this.isMine,
    this.senderDisplayName,
    this.showSenderName = false,
    this.replyPreview,
    this.onReplyTap,
    this.isSeenByPeer = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bg = item.message.deletedForEveryone
        ? c.surfaceMuted
        : (isMine ? c.primary : c.surfaceMuted);
    final fg = item.message.deletedForEveryone
        ? c.onSurface
        : (isMine ? c.onPrimary : c.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSenderName && !isMine && senderDisplayName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 6),
                  child: Text(
                    senderDisplayName!,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (replyPreview != null && !item.message.deletedForEveryone)
                _ReplyChip(
                  preview: replyPreview!,
                  onTap: onReplyTap,
                  isMine: isMine,
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _body(c, fg),
              ),
              const SizedBox(height: 2),
              _footer(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppColors c, Color fg) {
    if (item.message.deletedForEveryone) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.ban, size: 14, color: c.onSurfaceMuted),
          const SizedBox(width: 6),
          Text(
            'Message unsent',
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    switch (item.message.contentType) {
      case MessageContentType.text:
        return Text(
          item.message.content ?? '',
          style: TextStyle(color: fg, fontSize: 15),
        );
      case MessageContentType.voice:
        return VoiceMessageContent(item: item, isMine: isMine);
      case MessageContentType.share:
        final preview = item.message.sharedResource;
        if (preview == null) {
          return Text(
            'Shared content',
            style: TextStyle(color: fg),
          );
        }
        return ShareMessageContent(
          preview: preview,
          caption: item.message.content,
          isMine: isMine,
        );
    }
  }

  Widget _footer(AppColors c) {
    final when = tryParseChatTime(item.message.createdAt);
    final time = when != null ? formatChatBubbleTime(when) : '';
    final edited = item.message.editedAt != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (edited) ...[
            Text(
              'edited · ',
              style: TextStyle(color: c.onSurfaceMuted, fontSize: 10),
            ),
          ],
          Text(
            time,
            style: TextStyle(color: c.onSurfaceMuted, fontSize: 10),
          ),
          if (isMine) ...[
            const SizedBox(width: 4),
            _deliveryIcon(c),
          ],
        ],
      ),
    );
  }

  Widget _deliveryIcon(AppColors c) {
    if (item.message.deletedForEveryone) return const SizedBox.shrink();
    switch (item.state) {
      case MessageDeliveryState.pending:
        return Icon(
          TablerIcons.clock,
          size: 11,
          color: c.onSurfaceMuted,
        );
      case MessageDeliveryState.failed:
        return Icon(
          TablerIcons.alert_circle,
          size: 11,
          color: c.danger,
        );
      case MessageDeliveryState.sent:
        if (isSeenByPeer) {
          return Icon(
            TablerIcons.checks,
            size: 12,
            color: c.success,
          );
        }
        return Icon(
          TablerIcons.check,
          size: 11,
          color: c.onSurfaceSecondary,
        );
    }
  }
}

class _ReplyChip extends StatelessWidget {
  final ReplyPreview preview;
  final VoidCallback? onTap;
  final bool isMine;
  const _ReplyChip({
    required this.preview,
    required this.isMine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canTap = !preview.isOutOfWindow && onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: canTap ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                  color: isMine ? c.primary : c.onSurfaceMuted,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  preview.isOutOfWindow
                      ? LocaleKeys.chat_message_bubble_original_reply.tr()
                      : (preview.senderDisplayName ??
                          LocaleKeys.chat_message_bubble_reply_fallback.tr()),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!preview.isOutOfWindow &&
                    preview.snippet != null &&
                    preview.snippet!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    preview.snippet!,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
