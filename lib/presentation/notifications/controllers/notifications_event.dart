part of 'notifications_bloc.dart';

sealed class NotificationsEvent {}

class GetNotifications extends NotificationsEvent {}
class GetUnreadCount extends NotificationsEvent {}
class MarkNotificationRead extends NotificationsEvent {
  final String notificationId;
  MarkNotificationRead(this.notificationId);
}
class MarkAllNotificationsRead extends NotificationsEvent {}
class ClearNotifications extends NotificationsEvent {}
