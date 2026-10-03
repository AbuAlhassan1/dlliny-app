import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/notification_response.dart';

class NotificationTile extends StatelessWidget {
  final NotificationResponse notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = context.pickBilingual(
      ar: notification.titleAr,
      en: notification.titleEn,
    );
    final body = context.pickBilingual(
      ar: notification.bodyAr,
      en: notification.bodyEn,
    );
    final isAdminBroadcast = notification.type == 'admin_broadcast';

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.read
            ? Colors.transparent
            : c.onSurface.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdminBroadcast)
              const _DllinyTeamBadge()
            else
              CircleAvatar(
                radius: 22,
                backgroundColor: c.surfaceMuted,
                backgroundImage: notification.actorAvatarUrl != null
                    ? CachedNetworkImageProvider(notification.actorAvatarUrl!)
                    : null,
                child: notification.actorAvatarUrl == null
                    ? Icon(TablerIcons.bell, color: c.onSurface, size: 20)
                    : null,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 14,
                      fontWeight: notification.read
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DllinyTeamBadge extends StatelessWidget {
  const _DllinyTeamBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surfaceMuted,
              border: Border.all(color: c.border, width: 1),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/logo.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
          PositionedDirectional(
            bottom: -2,
            end: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
                border: Border.all(color: c.background, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(
                TablerIcons.discount_check_filled,
                size: 10,
                color: c.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
