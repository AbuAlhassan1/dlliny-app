import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hangout/core/notifications/fcm_service.dart';
import 'package:hangout/core/notifications/incoming_notification.dart';
import 'package:hangout/presentation/chat/active_conversation_tracker.dart';
import 'package:hangout/presentation/notifications/notification_navigator.dart';
import 'package:hangout/presentation/notifications/widgets/notification_banner.dart';

class NotificationBannerHost extends StatefulWidget {
  final Widget child;
  const NotificationBannerHost({super.key, required this.child});

  @override
  State<NotificationBannerHost> createState() => _NotificationBannerHostState();
}

class _NotificationBannerHostState extends State<NotificationBannerHost> {
  StreamSubscription<IncomingNotification>? _sub;
  IncomingNotification? _current;
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _sub = FcmService.instance.onIncomingNotification.listen(_onIncoming);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onIncoming(IncomingNotification notification) {
    if (!mounted) return;
    final type = notification.type;
    if (type == 'CHAT_MESSAGE_SENT' || type == 'CHAT_MESSAGE_REQUEST') {
      final activeId = ActiveConversationTracker.instance.conversationId;
      final convoId =
          notification.entityId ?? notification.data['conversationId'];
      if (activeId != null && activeId == convoId) return;
    }
    setState(() {
      _current = notification;
      _bannerKey = UniqueKey();
    });
  }

  void _clear() {
    if (!mounted) return;
    setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NotificationBanner(
              key: _bannerKey,
              notification: _current!,
              onTap: () => routeFromIncomingNotification(_current!),
              onDismissed: _clear,
            ),
          ),
      ],
    );
  }
}
