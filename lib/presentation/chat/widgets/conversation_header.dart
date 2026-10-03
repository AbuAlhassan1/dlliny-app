import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/widgets/relative_time.dart';

class ConversationHeader extends StatelessWidget {
  final ConversationResponse? conversation;
  final String? viewerUserId;
  final Map<String, DateTime> typingByMember;
  final bool? peerOnline;
  final String? peerLastSeenAt;

  const ConversationHeader({
    super.key,
    required this.conversation,
    required this.viewerUserId,
    this.typingByMember = const {},
    this.peerOnline,
    this.peerLastSeenAt,
  });

  ChatMemberResponse? get _peer {
    final c = conversation;
    if (c == null || c.type != ConversationType.direct) return null;
    for (final m in c.members) {
      if (m.memberType == ChatMemberType.user && m.memberId == viewerUserId) {
        continue;
      }
      return m;
    }
    return c.members.isNotEmpty ? c.members.first : null;
  }

  String get _title {
    final c = conversation;
    if (c == null) return 'Loading...';
    if (c.type == ConversationType.group) {
      return c.title?.trim().isNotEmpty == true ? c.title! : 'Group';
    }
    return _peer?.displayName ?? 'Conversation';
  }

  String? get _avatarUrl {
    final c = conversation;
    if (c == null) return null;
    return c.type == ConversationType.group ? c.avatarUrl : _peer?.avatarUrl;
  }

  String? _subtitle() {
    if (typingByMember.isNotEmpty) {
      final c = conversation;
      if (c == null) return LocaleKeys.chat_presence_typing.tr();
      final typists = <String>[];
      for (final id in typingByMember.keys) {
        for (final m in c.members) {
          if (m.memberId == id) {
            final name = m.displayName;
            if (name != null && name.isNotEmpty) typists.add(name);
            break;
          }
        }
        if (typists.length >= 2) break;
      }
      if (typists.isEmpty) return LocaleKeys.chat_presence_typing.tr();
      if (typists.length == 1) return '${typists.first} يكتب…';
      return '${typists.first}، ${typists.last} يكتبون…';
    }
    if (peerOnline == true) return LocaleKeys.chat_presence_online_now.tr();
    if (peerOnline == false && peerLastSeenAt != null) {
      final parsed = DateTime.tryParse(peerLastSeenAt!);
      if (parsed == null) return null;
      return LocaleKeys.chat_presence_last_seen.tr(
        namedArgs: {'time': formatChatRelative(parsed.toLocal())},
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final subtitle = _subtitle();
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.divider,
          ),
          child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: _avatarUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 96,
                  errorWidget: (_, _, _) => Icon(
                    TablerIcons.user,
                    color: c.onSurfaceSecondary,
                    size: 18,
                  ),
                )
              : Icon(
                  conversation?.type == ConversationType.group
                      ? TablerIcons.users
                      : TablerIcons.user,
                  color: c.onSurfaceSecondary,
                  size: 18,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
