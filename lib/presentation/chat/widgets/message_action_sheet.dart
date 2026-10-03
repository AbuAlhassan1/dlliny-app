import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';

enum MessageAction {
  reply,
  copy,
  edit,
  forward,
  unsend,
  deleteForMe,
}

Future<MessageAction?> showMessageActionSheet(
  BuildContext context, {
  required MessageDisplayItem item,
  required bool isMine,
}) {
  final actions = _resolveActions(item, isMine: isMine);
  if (actions.isEmpty) return Future.value(null);
  final c = context.c;
  return showModalBottomSheet<MessageAction>(
    context: context,
    backgroundColor: c.surfaceMuted,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.onSurfaceDisabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          for (final a in actions)
            _Tile(
              action: a,
              onTap: () => Navigator.of(sheetCtx).pop(a),
            ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}

List<MessageAction> _resolveActions(
  MessageDisplayItem item, {
  required bool isMine,
}) {
  if (item.message.deletedForEveryone) return const [];
  if (item.isPending) return const [];

  final isText = item.message.contentType == MessageContentType.text;
  final created = DateTime.tryParse(item.message.createdAt);
  final withinEdit = created != null &&
      DateTime.now().toUtc().difference(created.toUtc()).inMinutes < 15;

  final isShare = item.message.contentType == MessageContentType.share &&
      item.message.sharedResource != null;

  if (isMine) {
    return [
      MessageAction.reply,
      if (isText) MessageAction.copy,
      if (isText && withinEdit) MessageAction.edit,
      if (isShare) MessageAction.forward,
      MessageAction.unsend,
      MessageAction.deleteForMe,
    ];
  }
  return [
    MessageAction.reply,
    if (isText) MessageAction.copy,
    if (isShare) MessageAction.forward,
    MessageAction.deleteForMe,
  ];
}

class _Tile extends StatelessWidget {
  final MessageAction action;
  final VoidCallback onTap;
  const _Tile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDestructive = action == MessageAction.unsend ||
        action == MessageAction.deleteForMe;
    final color = isDestructive ? c.danger : c.onSurface;
    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      leading: Icon(_iconFor(action), color: color, size: 20),
      title: Text(
        _labelFor(action),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }

  IconData _iconFor(MessageAction a) {
    switch (a) {
      case MessageAction.reply:
        return TablerIcons.corner_up_left;
      case MessageAction.copy:
        return TablerIcons.copy;
      case MessageAction.edit:
        return TablerIcons.pencil;
      case MessageAction.forward:
        return TablerIcons.send;
      case MessageAction.unsend:
        return TablerIcons.ban;
      case MessageAction.deleteForMe:
        return TablerIcons.trash;
    }
  }

  String _labelFor(MessageAction a) {
    switch (a) {
      case MessageAction.reply:
        return LocaleKeys.chat_message_actions_reply.tr();
      case MessageAction.copy:
        return LocaleKeys.chat_message_actions_copy.tr();
      case MessageAction.edit:
        return LocaleKeys.chat_message_actions_edit.tr();
      case MessageAction.forward:
        return LocaleKeys.chat_message_actions_resend.tr();
      case MessageAction.unsend:
        return LocaleKeys.chat_message_actions_unsend.tr();
      case MessageAction.deleteForMe:
        return LocaleKeys.chat_message_actions_delete_for_me.tr();
    }
  }
}
