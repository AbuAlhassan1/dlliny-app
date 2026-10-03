import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/widgets/relative_time.dart';

class InboxConversationTile extends StatelessWidget {
  final ConversationResponse conversation;
  final String? viewerUserId;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isInFlight;

  const InboxConversationTile({
    super.key,
    required this.conversation,
    this.viewerUserId,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.isInFlight = false,
  });

  ChatMemberResponse? get _peer {
    if (conversation.type != ConversationType.direct) return null;
    if (viewerUserId == null) {
      return conversation.members.isNotEmpty
          ? conversation.members.first
          : null;
    }
    for (final m in conversation.members) {
      if (m.memberType == ChatMemberType.user && m.memberId == viewerUserId) {
        continue;
      }
      return m;
    }
    return conversation.members.isNotEmpty
        ? conversation.members.first
        : null;
  }

  String get _title {
    if (conversation.type == ConversationType.group) {
      return conversation.title?.trim().isNotEmpty == true
          ? conversation.title!
          : 'Group';
    }
    return _peer?.displayName ?? 'Conversation';
  }

  List<String?> _firstTwoMemberAvatars() {
    final out = <String?>[];
    for (final m in conversation.members) {
      if (m.memberType == ChatMemberType.user && m.memberId == viewerUserId) {
        continue;
      }
      out.add(m.avatarUrl);
      if (out.length == 2) break;
    }
    return out;
  }

  String _previewSubtitle() {
    final last = conversation.lastMessage;
    if (last == null) return 'No messages yet';
    if (last.deletedForEveryone) return 'Message unsent';

    switch (last.contentType) {
      case MessageContentType.text:
        final text = (last.content ?? '').trim();
        return text.isEmpty ? '' : (text.length > 60 ? '${text.substring(0, 60)}…' : text);
      case MessageContentType.voice:
        final secs = last.audioDurationSeconds ?? 0;
        final m = secs ~/ 60;
        final s = secs % 60;
        final dur = m > 0
            ? '$m:${s.toString().padLeft(2, '0')}'
            : '0:${s.toString().padLeft(2, '0')}';
        return '🎤 Voice message · $dur';
      case MessageContentType.share:
        switch (last.sharedResource?.type) {
          case SharedResourceType.post:
            return '📷 Shared a post';
          case SharedResourceType.hangout:
            return '🎉 Shared a hangout';
          case SharedResourceType.venue:
            return '📍 Shared a venue';
          case SharedResourceType.user:
            return '👤 Shared a profile';
          case SharedResourceType.memory:
          case null:
            return 'Shared content';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final unread = conversation.unreadCount;
    final lastAt = tryParseChatTime(
      conversation.lastMessage?.createdAt ?? conversation.updatedAt,
    );
    final isItalic = conversation.lastMessage?.deletedForEveryone == true;
    final isRequest = onAccept != null || onReject != null;

    return Opacity(
      opacity: isInFlight ? 0.5 : 1,
      child: InkWell(
        onTap: isInFlight ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _AvatarSlot(
                isGroup: conversation.type == ConversationType.group,
                groupAvatarUrl: conversation.type == ConversationType.group
                    ? conversation.avatarUrl
                    : null,
                directAvatarUrl: conversation.type == ConversationType.direct
                    ? _peer?.avatarUrl
                    : null,
                groupMemberAvatars: _firstTwoMemberAvatars(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (conversation.muted) ...[
                          const SizedBox(width: 6),
                          Icon(
                            TablerIcons.bell_off,
                            size: 14,
                            color: c.onSurfaceSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isRequest)
                      Row(
                        children: [
                          _RequestButton(
                            label: LocaleKeys.chat_request_banner_accept.tr(),
                            color: c.primary,
                            textColor: c.onPrimary,
                            onTap: isInFlight ? null : onAccept,
                          ),
                          const SizedBox(width: 6),
                          _RequestButton(
                            label: LocaleKeys.chat_request_banner_reject.tr(),
                            color: c.surfaceMuted,
                            textColor: c.onSurface,
                            onTap: isInFlight ? null : onReject,
                          ),
                        ],
                      )
                    else
                      Text(
                        _previewSubtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread > 0
                              ? c.onSurface
                              : c.onSurfaceSecondary,
                          fontSize: 13,
                          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                          fontWeight:
                              unread > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lastAt != null)
                    Text(
                      formatChatRelative(lastAt),
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 11,
                      ),
                    ),
                  if (unread > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: c.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarSlot extends StatelessWidget {
  final bool isGroup;
  final String? groupAvatarUrl;
  final String? directAvatarUrl;
  final List<String?> groupMemberAvatars;

  const _AvatarSlot({
    required this.isGroup,
    required this.groupAvatarUrl,
    required this.directAvatarUrl,
    required this.groupMemberAvatars,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (!isGroup) {
      return _CircleAvatar(
        url: directAvatarUrl,
        size: 48,
        fallback: TablerIcons.user,
      );
    }
    final explicit = groupAvatarUrl;
    if (explicit != null && explicit.isNotEmpty) {
      return _CircleAvatar(
        url: explicit,
        size: 48,
        fallback: TablerIcons.users,
      );
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          if (groupMemberAvatars.isNotEmpty)
            Positioned(
              left: 0,
              top: 0,
              child: _CircleAvatar(
                url: groupMemberAvatars[0],
                size: 30,
                fallback: TablerIcons.user,
              ),
            ),
          if (groupMemberAvatars.length > 1)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: c.background,
                  shape: BoxShape.circle,
                ),
                child: _CircleAvatar(
                  url: groupMemberAvatars[1],
                  size: 30,
                  fallback: TablerIcons.user,
                ),
              ),
            ),
          if (groupMemberAvatars.isEmpty)
            Center(
              child: Icon(
                TablerIcons.users,
                color: c.onSurfaceSecondary,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final IconData fallback;

  const _CircleAvatar({
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final memWidth = (size * 3).round();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.divider,
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: memWidth,
              errorWidget: (_, _, _) => _fallbackIcon(c),
            )
          : _fallbackIcon(c),
    );
  }

  Widget _fallbackIcon(AppColors c) => Center(
        child: Icon(
          fallback,
          color: c.onSurfaceSecondary,
          size: size * 0.45,
        ),
      );
}

class _RequestButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  const _RequestButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
