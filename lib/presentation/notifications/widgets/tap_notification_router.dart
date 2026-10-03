import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hangout/core/notifications/fcm_service.dart';
import 'package:hangout/core/notifications/incoming_notification.dart';
import 'package:hangout/presentation/notifications/notification_navigator.dart';

class TapNotificationRouter extends StatefulWidget {
  final Widget child;
  const TapNotificationRouter({super.key, required this.child});

  @override
  State<TapNotificationRouter> createState() => _TapNotificationRouterState();
}

class _TapNotificationRouterState extends State<TapNotificationRouter> {
  StreamSubscription<IncomingNotification>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = FcmService.instance.consumePendingTap();
      if (pending != null) {
        routeFromIncomingNotification(pending);
      }
    });
    _sub = FcmService.instance.onTappedNotification.listen((notif) {
      FcmService.instance.consumePendingTap();
      if (!mounted) return;
      routeFromIncomingNotification(notif);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
