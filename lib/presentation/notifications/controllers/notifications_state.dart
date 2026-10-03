part of 'notifications_bloc.dart';

sealed class NotificationsState {
  final List<NotificationResponse> notifications;
  final int unreadCount;
  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
  });
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading({
    super.notifications,
    super.unreadCount,
  });
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    super.notifications,
    super.unreadCount,
  });
}

final class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(
    this.message, {
    super.notifications,
    super.unreadCount,
  });
}

final class UnreadCountUpdated extends NotificationsState {
  const UnreadCountUpdated({
    super.notifications,
    super.unreadCount,
  });
}
