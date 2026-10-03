part of 'manage_announcements_bloc.dart';

sealed class ManageAnnouncementsState {
  const ManageAnnouncementsState();
}

final class ManageAnnouncementsInitial extends ManageAnnouncementsState {
  const ManageAnnouncementsInitial();
}

final class ManageAnnouncementsLoading extends ManageAnnouncementsState {
  const ManageAnnouncementsLoading();
}

final class ManageAnnouncementsError extends ManageAnnouncementsState {
  final String message;
  const ManageAnnouncementsError(this.message);
}

final class ManageAnnouncementsLoaded extends ManageAnnouncementsState {
  final List<AnnouncementResponse> items;
  final bool hasMore;
  const ManageAnnouncementsLoaded({
    required this.items,
    required this.hasMore,
  });
}

final class ManageAnnouncementsMutating extends ManageAnnouncementsState {
  final List<AnnouncementResponse> items;
  const ManageAnnouncementsMutating(this.items);
}

final class ManageAnnouncementsActionSucceeded
    extends ManageAnnouncementsState {
  final List<AnnouncementResponse> items;
  final String message;
  const ManageAnnouncementsActionSucceeded(this.items, this.message);
}

final class ManageAnnouncementsActionFailed extends ManageAnnouncementsState {
  final List<AnnouncementResponse> items;
  final String message;
  const ManageAnnouncementsActionFailed(this.items, this.message);
}
