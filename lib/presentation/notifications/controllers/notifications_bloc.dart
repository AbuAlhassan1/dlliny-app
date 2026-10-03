import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/notifications/fcm_service.dart';
import 'package:hangout/core/notifications/incoming_notification.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/notification_response.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  late final StreamSubscription<IncomingNotification> _fcmSub;

  List<NotificationResponse> _notifications = const [];
  int _unreadCount = 0;

  NotificationsBloc() : super(const NotificationsInitial()) {
    _fcmSub = FcmService.instance.onIncomingNotification.listen((_) {
      add(GetUnreadCount());
    });

    on<NotificationsEvent>((event, emit) {});

    on<GetNotifications>((event, emit) async {
      emit(NotificationsLoading(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));

      ApiResponse<PagedResponse<NotificationResponse>> response;
      try {
        response = await apiService.getNotifications();
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(NotificationsError(
          'Failed to load notifications',
          notifications: _notifications,
          unreadCount: _unreadCount,
        ));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _notifications = response.data!.content;
        _unreadCount = _notifications.where((n) => !n.read).length;
        emit(NotificationsLoaded(
          notifications: _notifications,
          unreadCount: _unreadCount,
        ));
      } else {
        emit(NotificationsError(
          response.error ?? 'Failed to load notifications',
          notifications: _notifications,
          unreadCount: _unreadCount,
        ));
      }
    });

    on<GetUnreadCount>((event, emit) async {
      ApiResponse<UnreadCountResponse> response;
      try {
        response = await apiService.getUnreadCount();
      } on DioException catch (_) {
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _unreadCount = response.data!.count;
        emit(UnreadCountUpdated(
          notifications: _notifications,
          unreadCount: _unreadCount,
        ));
      }
    });

    on<MarkNotificationRead>((event, emit) async {
      final index =
          _notifications.indexWhere((n) => n.id == event.notificationId);
      if (index == -1 || _notifications[index].read) return;

      final original = _notifications[index];
      final flipped = NotificationResponse(
        id: original.id,
        type: original.type,
        titleAr: original.titleAr,
        titleEn: original.titleEn,
        bodyAr: original.bodyAr,
        bodyEn: original.bodyEn,
        deepLink: original.deepLink,
        actorId: original.actorId,
        actorUsername: original.actorUsername,
        actorAvatarUrl: original.actorAvatarUrl,
        entityId: original.entityId,
        entityType: original.entityType,
        read: true,
        createdAt: original.createdAt,
      );
      _notifications = [..._notifications]..[index] = flipped;
      if (_unreadCount > 0) _unreadCount -= 1;
      emit(NotificationsLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));

      try {
        await apiService.markNotificationRead(event.notificationId);
      } on DioException catch (_) {
        _notifications = [..._notifications]..[index] = original;
        _unreadCount += 1;
        if (emit.isDone) return;
        emit(NotificationsLoaded(
          notifications: _notifications,
          unreadCount: _unreadCount,
        ));
      }
    });

    on<MarkAllNotificationsRead>((event, emit) async {
      if (_unreadCount == 0) return;

      final originals = _notifications;
      _notifications = _notifications
          .map((n) => NotificationResponse(
                id: n.id,
                type: n.type,
                titleAr: n.titleAr,
                titleEn: n.titleEn,
                bodyAr: n.bodyAr,
                bodyEn: n.bodyEn,
                deepLink: n.deepLink,
                actorId: n.actorId,
                actorUsername: n.actorUsername,
                actorAvatarUrl: n.actorAvatarUrl,
                entityId: n.entityId,
                entityType: n.entityType,
                read: true,
                createdAt: n.createdAt,
              ))
          .toList();
      final originalCount = _unreadCount;
      _unreadCount = 0;
      emit(NotificationsLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));

      try {
        await apiService.markAllNotificationsRead();
      } on DioException catch (_) {
        _notifications = originals;
        _unreadCount = originalCount;
        if (emit.isDone) return;
        emit(NotificationsLoaded(
          notifications: _notifications,
          unreadCount: _unreadCount,
        ));
      }
    });

    on<ClearNotifications>((event, emit) {
      _notifications = const [];
      _unreadCount = 0;
      emit(const NotificationsInitial());
    });
  }

  @override
  Future<void> close() {
    _fcmSub.cancel();
    return super.close();
  }
}
