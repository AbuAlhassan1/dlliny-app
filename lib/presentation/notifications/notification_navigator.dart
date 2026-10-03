import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/notifications/incoming_notification.dart';
import 'package:hangout/core/router/routes.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/notification_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/chat/screens/conversation_page_wrapper.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/post_details_page_wrapper.dart';
import 'package:hangout/presentation/notifications/notifications_page_wrapper.dart';
import 'package:hangout/presentation/points/pages/points_page_wrapper.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';

NavigatorState? get _navigator => appNavigatorKey.currentState;

bool openNotification(NotificationResponse n) {
  final navigator = _navigator;
  if (navigator == null) return false;
  switch (n.type) {
    case 'NEW_FOLLOWER':
      final username = n.actorUsername;
      if (username == null) return false;
      navigator.push(
        MaterialPageRoute(builder: (_) => ProfilePageWrapper(username: username)),
      );
      return true;

    case 'POST_LIKED':
    case 'POST_COMMENTED':
      final id = n.entityId;
      if (id == null) return false;
      _openPostById(id);
      return true;

    case 'HANGOUT_CREATED':
    case 'HANGOUT_INVITATION':
    case 'HANGOUT_ACCEPTED':
    case 'HANGOUT_CANCELLED':
      final id = n.entityId;
      if (id == null || id.isEmpty) return false;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => HangoutDetailsPageWrapper(hangoutId: id),
        ),
      );
      return true;

    case 'LEVEL_UP':
      navigator.push(
        MaterialPageRoute(builder: (_) => const PointsPageWrapper()),
      );
      return true;

    case 'CHAT_MESSAGE_SENT':
    case 'CHAT_MESSAGE_REQUEST':
      final convoId = n.entityId;
      if (convoId == null || convoId.isEmpty) return false;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ConversationPageWrapper(conversationId: convoId),
        ),
      );
      return true;

    case 'admin_broadcast':
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const NotificationsPageWrapper(),
        ),
      );
      return true;

    case 'WELCOME':
    default:
      return false;
  }
}

bool routeFromIncomingNotification(IncomingNotification n) {
  final entityId = n.entityId ?? n.data['conversationId'];
  final synthesised = NotificationResponse(
    id: '',
    type: n.type ?? '',
    titleAr: n.titleAr ?? n.title ?? '',
    titleEn: n.titleEn ?? n.title ?? '',
    bodyAr: n.bodyAr ?? n.body ?? '',
    bodyEn: n.bodyEn ?? n.body ?? '',
    deepLink: n.deepLink,
    actorId: n.data['actorId'],
    actorUsername: n.actorUsername,
    actorAvatarUrl: n.actorAvatarUrl,
    entityId: entityId,
    entityType: n.entityType,
    read: false,
    createdAt: DateTime.now().toIso8601String(),
  );
  return openNotification(synthesised);
}

Future<void> _openPostById(String postId) async {
  final api = serviceLocator.get<ApiService>();
  try {
    final res = await api.getPost(postId);
    if (!res.success || res.data == null) {
      log('openPost: getPost failed: ${res.error}');
      return;
    }
    final navigator = _navigator;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => PostDetailsPageWrapper(post: res.data as PostResponse),
      ),
    );
  } catch (e) {
    log('openPost: exception: $e');
  }
}
